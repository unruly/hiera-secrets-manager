Gem::Specification.new do |spec|
  spec.name        = 'hiera-secrets-manager'
  spec.version     = '1.1.0'

  spec.authors     = ['Unruly']
  spec.email       = 'boss@unrulygroup.com'

  spec.summary     = 'AWS Secrets Manager backend for Hiera'
  spec.description = 'Hiera-Secrets-Manager is a backend for Hiera which can look up secrets from AWS Secrets Manager.'

  spec.add_runtime_dependency 'aws-sdk-secretsmanager', '1.11.0'

  spec.files       = Dir.glob('lib/**/*')
  spec.test_files  = Dir.glob('spec/**/*_spec.rb')

  spec.homepage    = 'https://github.com/unruly/hiera-secrets-manager'
  spec.license     = 'MIT'
end
