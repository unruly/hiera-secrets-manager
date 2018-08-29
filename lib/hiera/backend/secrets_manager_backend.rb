class Hiera
  module Backend
    class Secrets_manager_backend
      def initialize
        require 'aws-sdk-secretsmanager'
        @config = Config
        @client = create_client
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil

        if @client.nil?
          Hiera.debug('Key lookup failed. AWS Secrets Manager backend is in a bad state.')
          return answer
        end

        if contains_illegal_characters?(key)
          Hiera.debug("#{key} contains illegal characters. Skipping lookup.")
          return answer
        end

        key_to_query = format_key(key, scope, Config[:secrets_manager])

        begin
          answer = @client.get_secret_value(secret_id: key_to_query)['secret_string']
        rescue Aws::SecretsManager::Errors::ResourceNotFoundException => error
          Hiera.debug("#{key} not found: #{error.message}")
        rescue StandardError => error
          Hiera.debug("AWS Secrets Manager Error: #{error}")
        end

        answer
      end

      private

      # AWS Secrets Manager only allows alphanumeric characters or (/_+=.@-) in key names
      # GetSecret requests will fail for keys which have illegal characters
      def contains_illegal_characters?(key)
        %r{^[a-zA-Z0-9\/_+=.@\-]+$}.match(key).nil?
      end

      def get_prefix(environments, scope)
        if environments && environments.key?(scope['environment'])
          environments[scope['environment']]
        else
          scope['environment']
        end
      end

      def format_key(key, scope, config)
        if scope.include?('environment') && scope['environment']
          environments = config[:environments]
          prefix = get_prefix(environments, scope)
          "#{prefix}/#{key}"
        else
          key
        end
      end

      def create_client
        if missing_config?
          Hiera.debug('Warning! Config is empty. Starting in a bad state.')
          return nil
        end

        if missing_keys?
          Hiera.debug("Warning! Missing key(s) #{missing_keys} in Config. Starting in a bad state.")
          return nil
        end

        Hiera.debug('AWS Secrets Manager backend starting')
        Aws::SecretsManager::Client.new(
          region: @config[:secrets_manager][:region],
          access_key_id: @config[:secrets_manager][:access_key_id],
          secret_access_key: @config[:secrets_manager][:secret_access_key]
        )
      end

      def missing_config?
        @config[:secrets_manager].nil?
      end

      def missing_keys?
        !missing_keys.empty?
      end

      def missing_keys
        %i[region access_key_id secret_access_key].reject do |key|
          @config[:secrets_manager].include?(key)
        end
      end
    end
  end
end
