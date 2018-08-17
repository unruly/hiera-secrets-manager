class Hiera
  module Backend
    class Secrets_manager_backend
      def initialize()
        require 'aws-sdk-secretsmanager'

        # Initialises a new instance of the AWS Secrets Manager client
        @client = Aws::SecretsManager::Client.new(region: Config[:secrets_manager][:region])

        Hiera.debug("AWS Secrets Manager backend starting")
      end

      # lookup() is called by Hiera to return a secret, and is required by Hiera to work
      def lookup(key, scope, order_override, resolution_type)

        # If lookup() returns `nil`, it will proceed to the next available backend (possible Hiera)
        answer = nil

        # begin / rescue / end is like a try / catch,
        # and will ensure Hiera doesn't break if the Secrets Manager library doesn't work properly
        begin

          # queries Secrets Manager for the value of the key passed
          # 'secret_string' contains the actual plaintext secret
          answer = @client.get_secret_value({secret_id: key})['secret_string']

        #   Catches any errors, and outputs a debug message
        rescue Aws::SecretsManager::Errors::ResourceNotFoundException => error
          Hiera.debug("#{key} not found: #{error.message}")
        end

        # Implicitly returns answer, which will either be nil or the actual answer!
        answer
      end
    end
  end
end