class Hiera
  module Backend
    class Secrets_manager_backend
      def initialize
        require 'json'
        require 'aws-sdk-secretsmanager'
        require 'hiera/interpolate'
        @config = Config
        @client = create_client
      end

      def lookup(key, scope, order_override, resolution_type)
        if @config[:secrets_manager].key?(:confine_to_keys)
          confine_keys = @config[:secrets_manager][:confine_to_keys]
          unless confine_keys.is_a?(Array)
            Hiera.warn("Hiera Secrets Manager confine_to_keys must be an array")
          end

          begin
            confine_keys = confine_keys.map { |r| Regexp.new(r) }
          rescue StandardError => err
            Hiera.warn("Hiera Secrets Manager Failed to create regexp with error #{err}")
          end
          match = Regexp.union(confine_keys)
          unless key[match] == key
            Hiera.debug("Hiera Secrets Manager ignoring #{key}, not in confine_to_keys")
            return nil
          end
        end

        answer = nil

        if @client.nil?
          Hiera.debug('Key lookup failed. AWS Secrets Manager backend is in a bad state.')
          return answer
        end

        if contains_illegal_characters?(key)
          Hiera.debug("Hiera Secrets Manager #{key} contains illegal characters. Skipping lookup.")
          return answer
        end

        key_to_query = format_key(key, scope, Config[:secrets_manager])

        begin
          case resolution_type
          when :array
            Hiera.warn("Hiera Secrets Manager backend does not support arrays.")
          when :hash
            answer = JSON.parse(retrieve_secret(key_to_query))
          else
            key_to_query, key = key_to_query.split('::',2)
            answer = retrieve_secret(key_to_query)
            answer = JSON.parse(answer)[key] if key
          end
        rescue Aws::SecretsManager::Errors::ResourceNotFoundException => error
          Hiera.debug("#{key_to_query} not found: #{error.message}")
        rescue StandardError => error
          Hiera.debug("Secrets Manager Backend Error:")
          Hiera.debug(error)
        end

        answer
      end

      private

      # AWS Secrets Manager only allows alphanumeric characters or (/_+=.@-) in key names
      # GetSecret requests will fail for keys which have illegal characters
      def contains_illegal_characters?(key)
        %r{^[a-zA-Z0-9\/_+=.@\-:]+$}.match(key).nil?
      end

      def parse_string(data, scope, extra_data={})
        Hiera::Interpolate.interpolate(data, scope, extra_data)
      end

      def get_prefix(environments, scope)
        if @config[:secrets_manager].has_key?(:env)
          parse_string(@config[:secrets_manager][:env], scope)
        elsif environments && environments.key?(scope['environment'])
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

        end

        if !@config[:secrets_manager][:iam_client] and missing_keys?
          Hiera.debug("Warning! Missing key(s) #{missing_keys} in Config. Starting in a bad state.")
          return nil
        end

        Hiera.debug('AWS Secrets Manager backend starting')
        secrets_client
      end

      def secrets_client
        if @config[:secrets_manager][:iam_client]
          Hiera.debug('IAM Client')
          return Aws::SecretsManager::Client.new(region: @config[:secrets_manager][:region])
        end
        Aws::SecretsManager::Client.new(
            region: @config[:secrets_manager][:region],
            access_key_id: @config[:secrets_manager][:access_key_id],
            secret_access_key: @config[:secrets_manager][:secret_access_key])
      end

      def missing_config?
        @config[:secrets_manager].nil?
      end

      def missing_keys?
        !missing_keys.empty?
      end

      def missing_keys
        [:region, :access_key_id, :secret_access_key].reject do |key|
          @config[:secrets_manager].include?(key)
        end
      end

      def retrieve_secret(key)
        response = @client.get_secret_value(secret_id: key)
        Hiera.debug("Retrieved Secret '#{key}' with version '#{response['version_id']}'")
        response['secret_string']
      end
    end
  end
end