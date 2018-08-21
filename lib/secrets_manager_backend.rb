class Hiera
  module Backend
    class Secrets_manager_backend
      def initialize
        require 'aws-sdk-secretsmanager'
        @client = Aws::SecretsManager::Client.new(
          region: Config[:secrets_manager][:region]
        )

        Hiera.debug('AWS Secrets Manager backend starting')
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil

        key_to_query = format_key(key, scope, Config[:secrets_manager])

        begin
          answer = @client.get_secret_value(secret_id: key_to_query)['secret_string']
        rescue Aws::SecretsManager::Errors::ResourceNotFoundException => error
          Hiera.debug("#{key} not found: #{error.message}")
        end

        answer
      end

      def format_key(key, scope, config)
        if scope.key?('environment')
          environments = config[:environments]
          environment = scope['environment']
          if environments && environments.key?(environment)
            prefix = environments[environment]
          else
            prefix = environment
          end
          "#{prefix}/#{key}"
        else
          key
        end
      end
    end
  end
end
