$LOAD_PATH.insert(0, File.join([File.dirname(__FILE__), '..', 'lib']))

require 'rubygems'
require 'rspec'
require 'mocha'
require 'hiera'
require 'aws-sdk-secretsmanager'

RSpec.configure do |config|
  config.mock_with :mocha
end
