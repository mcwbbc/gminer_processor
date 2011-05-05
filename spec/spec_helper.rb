# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["DAEMON_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)

DaemonKit::Application.running!
RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

end
