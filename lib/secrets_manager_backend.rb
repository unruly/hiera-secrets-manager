class Hiera
  module Backend
    class Secrets_manager_backend
      def initialize
        require 'aws-sdk-secretsmanager'

        # Initialises a new instance of the AWS Secrets Manager client
        @client = Aws::SecretsManager::Client.new(
          region: Config[:secrets_manager][:region]
        )

        Hiera.debug('AWS Secrets Manager backend starting')
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil

        begin
          answer = @client.get_secret_value(secret_id: key)['secret_string']

        rescue Aws::SecretsManager::Errors::ResourceNotFoundException => error
          Hiera.debug("#{key} not found: #{error.message}")
        end

        answer
      end
    end
  end
end
