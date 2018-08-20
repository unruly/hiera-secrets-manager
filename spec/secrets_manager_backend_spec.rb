require 'spec_helper'
require 'secrets_manager_backend'

class Hiera
  module Backend
    describe Secrets_manager_backend do
      before do
        @config_object = { secrets_manager: { region: 'some_region' } }
        Config.load(@config_object)
        Hiera.stubs(:debug)
        Aws::SecretsManager::Client
          .stubs(:new)
          .with(@config_object[:secrets_manager])
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
            .with(@config_object[:secrets_manager])
          Secrets_manager_backend.new
        end
      end

      describe '#lookup' do
        before do
          @mock_client = mock('client')
          Aws::SecretsManager::Client
            .stubs(:new)
            .with(@config_object[:secrets_manager]).returns(@mock_client)
          @backend = Secrets_manager_backend.new
        end

        it 'should return a secret that exists' do
          secret_name = 'secret_name'
          secret_string = 'i_am_a_secret'

          @mock_client.stubs(:get_secret_value)
                      .with(secret_id: secret_name)
                      .returns('secret_string' => secret_string)

          answer = @backend.lookup(secret_name, nil, nil, nil)
          expect(answer).to eq(secret_string)
        end

        it 'should not return a secret that does not exist' do
          nonexistent_secret = 'does_not_exist'
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
                      .with(secret_id: nonexistent_secret)
                      .raises(error)
          Hiera
            .expects(:debug)
            .with("#{nonexistent_secret} not found: #{error_message}")
          answer = @backend.lookup(nonexistent_secret, nil, nil, nil)
          expect(answer).to eq(nil)
        end
      end
    end
  end
end
