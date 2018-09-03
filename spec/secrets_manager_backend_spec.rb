require 'spec_helper'
require 'hiera/backend/secrets_manager_backend'

class Hiera
  module Backend
    describe Secrets_manager_backend do
      before(:each) do
        @region_object = { region: 'some_region' }
        @credentials = { access_key_id: 'some_id',
                         secret_access_key: 'some_access_key' }
        @config_object = { secrets_manager:
                             {
                               region: @region_object[:region],
                               access_key_id: @credentials[:access_key_id],
                               secret_access_key: @credentials[:secret_access_key],
                               environments:
                                     {
                                       'env1' => 'production',
                                       'env2' => 'staging',
                                       'env3' => 'development'
                                     }
                             } }

        Config.load(@config_object)
        Hiera.stubs(:debug)
        @mock_client = mock('client')
        Aws::SecretsManager::Client
          .stubs(:new)
          .with(region: @region_object[:region],
                access_key_id: @credentials[:access_key_id],
                secret_access_key: @credentials[:secret_access_key])
          .returns(@mock_client)
      end

      def mock_scope_with_environment(environment)
        mock_scope = mock
        mock_scope.stubs(:lookupvar).with('environment').returns(environment)
        Hiera::Scope.new(mock_scope)
      end

      describe '#initialize' do
        it 'should announce its creation' do
          Hiera
            .expects(:debug)
            .with('AWS Secrets Manager backend starting')
          Secrets_manager_backend.new
        end

        it 'should set up a connection to AWS Secrets Manager' do
          Aws::SecretsManager::Client
            .expects(:new)
            .with(region: @region_object[:region],
                  access_key_id: @credentials[:access_key_id],
                  secret_access_key: @credentials[:secret_access_key])
          Secrets_manager_backend.new
        end

        context 'with bad config' do
          after do
            Secrets_manager_backend.new
          end

          it 'with empty config, should announce that it has no config' do
            config_object = {}
            Config.load(config_object)
            Hiera
              .expects(:debug)
              .with('Warning! Config is empty. Starting in a bad state.')
          end

          it 'with no params, should announce that it is in a bad state' do
            config_object = { secrets_manager: {} }
            Config.load(config_object)
            Hiera
              .expects(:debug)
              .with('Warning! Missing key(s) [:region, :access_key_id, :secret_access_key] in Config. Starting in a bad state.')
          end

          [:region, :access_key_id, :secret_access_key].each do |key|
            it "debug should announce when key [#{key}] is missing in config" do
              @config_object[:secrets_manager].delete(key)
              Config.load(@config_object)
              Hiera
                .expects(:debug)
                .with("Warning! Missing key(s) [:#{key}] in Config. Starting in a bad state.")
            end
          end
        end
      end

      describe '#lookup' do
        before do
          @backend = Secrets_manager_backend.new
          @scope = mock_scope_with_environment('env1')
        end

        it 'should announce if it is in a bad state' do
          config_object = { secrets_manager: {} }
          Config.load(config_object)
          Hiera
            .expects(:debug)
            .with('Key lookup failed. AWS Secrets Manager backend is in a bad state.')
          backend = Secrets_manager_backend.new
          backend.lookup('some_secret', {}, nil, nil)
        end

        it 'should return a secret that exists' do
          secret_name = 'secret_name'
          secret_string = 'i_am_a_secret'
          prefixed_secret_name = 'production/secret_name'

          @mock_client.stubs(:get_secret_value)
                      .with(secret_id: prefixed_secret_name)
                      .returns('secret_string' => secret_string)

          answer = @backend.lookup(secret_name, @scope, nil, nil)
          expect(answer).to eq(secret_string)
        end

        it 'should log the secret version for successful lookup' do
          @mock_client.stubs(:get_secret_value)
                      .returns('version_id'    => 'secret_version_UUID',
                               'secret_string' => 'i_am_a_secret')
          Hiera
              .expects(:debug)
              .with("Retrieved Secret 'production/some_secret' with version 'secret_version_UUID'")
          @backend.lookup('some_secret', @scope, nil, nil)
        end

        it 'should not return a secret that does not exist' do
          nonexistent_secret = 'does_not_exist'
          prefixed_nonexistent_secret = 'production/does_not_exist'
          mock_context = {}
          error_message = 'Secrets Manager could not find this secret.'
          error = Aws::
                  SecretsManager::
                  Errors::
                  ResourceNotFoundException.new(
                    mock_context,
                    error_message
                  )
          @mock_client.stubs(:get_secret_value)
                      .with(secret_id: prefixed_nonexistent_secret)
                      .raises(error)
          Hiera
            .expects(:debug)
            .with("#{prefixed_nonexistent_secret} not found: #{error_message}")
          answer = @backend.lookup(nonexistent_secret, @scope, nil, nil)
          expect(answer).to eq(nil)
        end

        it 'should handle exceptions gracefully' do
          error_message = 'some_error'
          secret_name = 'some_secret'
          error = StandardError.new(
              error_message
          )
          @mock_client.stubs(:get_secret_value)
              .with(secret_id: secret_name)
              .raises(error)
          Hiera
              .expects(:debug)
              .with("Secrets Manager Backend Error:")
              .with(error)
          answer = @backend.lookup(secret_name, {}, nil, nil)
          expect(answer).to eq(nil)
        end

        it 'falls back to provided scope environment when Hiera config does not include environment as a key / value pair' do
          scope = mock_scope_with_environment('some_env_not_in_config')

          prefixed_secret_name = 'some_env_not_in_config/secret_name'

          @mock_client
            .expects(:get_secret_value)
            .with(secret_id: prefixed_secret_name)
            .returns('secret_string' => 'the_secret')
          @backend.lookup('secret_name', scope, nil, nil)
        end

        it 'falls back to provided scope environment when Hiera config does not include any environments' do
          incomplete_config = { secrets_manager: { region: @region_object[:region] } }
          Config.load(incomplete_config)

          scope = mock_scope_with_environment('some_env')

          prefixed_secret_name = 'some_env/secret_name'

          @mock_client
            .expects(:get_secret_value)
            .with(secret_id: prefixed_secret_name)
            .returns('secret_string' => 'the_secret')
          @backend.lookup('secret_name', scope, nil, nil)
        end

        it 'does not use prefix if no environment is provided in scope' do
          scope = mock_scope_with_environment(nil)

          secret_name = 'secret_name'

          @mock_client
            .expects(:get_secret_value)
            .with(secret_id: secret_name)
            .returns('secret_string' => 'the_secret')

          @backend.lookup(secret_name, scope, nil, nil)
        end

        context 'with illegal characters' do
          %w[: ~ # \\].each do |character|
            it "returns nil if key has illegal character [#{character}] (according to AWS)" do
              @mock_client
                  .expects(:get_secret_value)
                  .never

              secret_name = "secret#{character}name"

              Hiera
                  .expects(:debug)
                  .with("#{secret_name} contains illegal characters. Skipping lookup.")

              @backend.lookup(secret_name, @scope, nil, nil)
            end
          end
        end

        context 'resolution type' do
          it 'does not support arrays' do
            @mock_client
                .expects(:get_secret_value)
                .never
            Hiera
                .expects(:warn)
                .with("Hiera Secrets Manager backend does not support arrays.")
            answer = @backend.lookup('some_secret', {}, nil, :array)
            expect(answer).to eq(nil)
          end

          it 'parses hashes successfully' do
            secret_name = 'some_secret'
            @mock_client
                .expects(:get_secret_value)
                .with(secret_id: secret_name)
                .returns('secret_string' => '{"foo": "bar"}')
            answer = @backend.lookup(secret_name, {}, nil, :hash)
            expect(answer).to eq({ 'foo' => 'bar' })
          end

          it 'should announce if expecting hash and receiving string' do
            secret_name = 'some_secret'
            error = JSON::ParserError.new('unexpected token')
            @mock_client
                .expects(:get_secret_value)
                .with(secret_id: secret_name)
                .returns('secret_string' => 'some string')
            JSON
                .stubs(:parse)
                .raises(error)
            Hiera
                .expects(:debug)
                .with("Secrets Manager Backend Error:")
                .with(error)
            answer = @backend.lookup(secret_name, {}, nil, :hash)
            expect(answer).to eq(nil)
          end
        end
      end
    end
  end
end
