require 'spec_helper'
require 'hiera/backend/secrets_manager_backend'

class Hiera
  module Backend
    describe Secrets_manager_backend do
      before do
        @region_object = { region: 'some_region' }
        @config_object = { secrets_manager:
                               {
                                 region: @region_object[:region],
                                 environments:
                                       {
                                         'env1' => 'production',
                                         'env2' => 'staging',
                                         'env3' => 'development'
                                       }
                               } }
        Config.load(@config_object)
        Hiera.stubs(:debug)
        Aws::SecretsManager::Client
          .stubs(:new)
          .with(@region_object)
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
            .with(@region_object)
          Secrets_manager_backend.new
        end
      end

      describe '#lookup' do
        before do
          @mock_client = mock('client')
          Aws::SecretsManager::Client
            .stubs(:new)
            .with(@region_object).returns(@mock_client)
          @backend = Secrets_manager_backend.new
          @scope = { 'environment' => 'env1' }
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
            .with("#{nonexistent_secret} not found: #{error_message}")
          answer = @backend.lookup(nonexistent_secret, @scope, nil, nil)
          expect(answer).to eq(nil)
        end

        it 'falls back to provided scope environment when Hiera config does not include environment as a key / value pair' do
          scope = { 'environment' => 'some_env_not_in_config' }
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

          scope = { 'environment' => 'some_env' }
          prefixed_secret_name = 'some_env/secret_name'

          @mock_client
            .expects(:get_secret_value)
            .with(secret_id: prefixed_secret_name)
            .returns('secret_string' => 'the_secret')
          @backend.lookup('secret_name', scope, nil, nil)
        end

        it 'does not use prefix if no environment is provided in scope' do
          scope = { 'no_environment_key' => 'some_value' }
          secret_name = 'secret_name'

          @mock_client
            .expects(:get_secret_value)
            .with(secret_id: secret_name)
            .returns('secret_string' => 'the_secret')
          @backend.lookup('secret_name', scope, nil, nil)
        end
      end
    end
  end
end
