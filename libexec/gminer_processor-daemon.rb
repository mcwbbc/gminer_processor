# Generated amqp daemon

# Do your post daemonization configuration here
# At minimum you need just the first line (without the block), or a lot
# of strange things might start happening...
DaemonKit::Application.running! do |config|
  # Trap signals with blocks or procs
  # config.trap( 'INT' ) do
  #   # do something clever
  # end
  # config.trap( 'TERM', Proc.new { puts 'Going down' } )
  config.trap( 'INT', Proc.new { @processor.listen_queue.unsubscribe } )
  config.trap( 'TERM', Proc.new { @processor.listen_queue.unsubscribe } )
end

# IMPORTANT CONFIGURATION NOTE
#
# Please review and update 'config/amqp.yml' accordingly or this
# daemon won't work as advertised.

# Run an event-loop for processing
DaemonKit::AMQP.run do
  # Inside this block we're running inside the reactor setup by the
  # amqp gem. Any code in the examples (from the gem) would work just
  # fine here.

  # Uncomment this for connection keep-alive
  AMQP.conn.connection_status do |status|
    DaemonKit.logger.debug("AMQP connection status changed: #{status}")
    if status == :disconnected
      AMQP.conn.reconnect(true)
    end
  end

  @amq = ::MQ.new
  @amq.prefetch(1)
  @processor = GminerProcessor.new(@amq)
  @amq.queue(GminerProcessor::SCHEDULER_QUEUE_NAME, :durable => true).publish({'worker_key' => @processor.worker_key, 'command' => 'alive'}.to_json, :persistent => true)

#  DaemonKit.logger.debug("LAUNCHED: #{@processor.worker_key}")

  @processor.listen_queue.subscribe do |msg|
#    DaemonKit.logger.debug("MSG: #{msg}")
    @processor.process(msg)
  end

end
