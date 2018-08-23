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

        if contains_illegal_characters?(key)
          Hiera.debug("#{key} contains illegal characters. Skipping lookup.")
          return answer
        end

        key_to_query = format_key(key, scope, Config[:secrets_manager])

        begin
          answer = @client.get_secret_value(secret_id: key_to_query)['secret_string']
        rescue Aws::SecretsManager::Errors::ResourceNotFoundException => error
          Hiera.debug("#{key} not found: #{error.message}")
        end

        answer
      end

      private

      # AWS Secrets Manager only allows alphanumeric characters or (/_+=.@-) in key names
      # GetSecret requests will fail for keys which have illegal characters
      def contains_illegal_characters?(key)
        /^[a-zA-Z0-9\/_+=.@\-]+$/.match(key).nil?
      end

      def get_prefix(environments, scope)
        if environments && environments.key?(scope['environment'])
          environments[scope['environment']]
        else
          scope['environment']
        end
      end

      def format_key(key, scope, config)
        if scope.include?('environment') and scope['environment']
          environments = config[:environments]
          prefix = get_prefix(environments, scope)
          "#{prefix}/#{key}"
        else
          key
        end
      end
    end
  end
end
