begin
  require 'httparty'
rescue LoadError
  $stderr.puts "Missing httparty gem. Please run 'gem install httparty'."
  exit 1
end

require 'ncbo_exception'
require 'ncbo_annotator_service'
require 'ncbo_service'

begin
  require 'json'
rescue LoadError
  $stderr.puts "Missing json gem. Please run 'gem install json'."
  exit 1
end

begin
  require 'amqp'
  require 'mq'
rescue LoadError
  $stderr.puts "Missing amqp gem. Please run 'gem install amqp'."
  exit 1
end

begin
  require 'uuidtools'
rescue LoadError
  $stderr.puts "Missing uuidtools gem. Please run 'gem install uuidtools'."
  exit 1
end
