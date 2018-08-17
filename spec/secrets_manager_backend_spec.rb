require 'spec_helper'
require 'secrets_manager_backend'

class Hiera
  module Backend
    describe Secrets_manager_backend do
      before do
        @config_object = { :secrets_manager => { :region => "some_region" } }
        Config.load(@config_object)
        Hiera.stubs(:debug)
        Aws::SecretsManager::Client.stubs(:new).with(@config_object[:secrets_manager])
      end

      describe "#initialize" do

        it "should announce its creation" do
          Hiera.expects(:debug).with("AWS Secrets Manager backend starting")
          Secrets_manager_backend.new
        end

        it "should set up a connection to AWS Secrets Manager" do
          Aws::SecretsManager::Client.expects(:new).with(@config_object[:secrets_manager])
          Secrets_manager_backend.new
        end

      end

      describe '#lookup' do
        before do
          @secret_name = "secret_name"
          @secret_string = "i_am_a_secret"
          @mock_client = mock('client')
          @mock_client.stubs(:get_secret_value).with({ secret_id: @secret_name }).returns('secret_string' => @secret_string)
          Aws::SecretsManager::Client.stubs(:new).with(@config_object[:secrets_manager]).returns(@mock_client)
          @backend = Secrets_manager_backend.new
        end

        it "should return a secret that exists" do
          answer = @backend.lookup(@secret_name, nil, nil, nil)
          expect(answer).to eq(@secret_string)
        end
      end
    end
  end
end