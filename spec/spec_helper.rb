$LOAD_PATH.insert(0, File.join([File.dirname(__FILE__), '..', 'lib']))

require 'simplecov'
require 'simplecov-console'
require 'rubygems'
require 'rspec'
require 'mocha'
require 'hiera'
require 'aws-sdk-secretsmanager'
require 'hiera/scope'

SimpleCov.formatter = SimpleCov::Formatter::Console
SimpleCov.start

RSpec.configure do |config|
  config.mock_with :mocha
end
