# Your starting point for daemon specific classes. This directory is
# already included in your load path, so no need to specify it.

class GminerProcessor

  SCHEDULER_QUEUE_NAME = 'gminer-scheduler'
  DATABASER_QUEUE_NAME = 'gminer-databaser'

  attr_accessor :worker_key, :mq, :processing, :listen_queue, :databaser_queue

  def initialize(mq)
    @processing = false
    @mq = mq
    @worker_key = UUIDTools::UUID.random_create.to_s
    @databaser_queue = mq.queue(GminerProcessor::DATABASER_QUEUE_NAME, :durable => true)
    @listen_queue = mq.queue(@worker_key, :auto_delete => true)
  end

  def publish(name, msg)
    mq.queue(name, :durable => true).publish(msg, :persistent => true)
#    message = JSON.parse(msg)
#    DaemonKit.logger.debug("#{worker_key} SENT: #{message['command']}")
  end

  def save_term(params)
    databaser_message({'command' => 'saveterm'}.merge!(params).to_json)
  end

  def save_annotation(params)
    databaser_message({'command' => 'saveannotation'}.merge!(params).to_json)
  end

  def save_closure(params)
    databaser_message({'command' => 'saveclosure'}.merge!(params).to_json)
  end


  def databaser_message(msg)
    databaser_queue.publish(msg)
  end

  def create_for(geo_accession, field_name, field_value, description, ncbo_id, ontology_name, stopwords, expand_ontologies, email)
    cleaned = field_value.gsub(/[\r\n]+/, " ")
    term_hash, ontology_hash = NCBOAnnotatorService.result_hash(cleaned, stopwords, expand_ontologies, ncbo_id, email)
    process_ncbo_results(term_hash, ontology_hash, geo_accession, field_name, field_value, description)
  end

  def process_ncbo_results(hash, ontology_hash, geo_accession, field_name, field_value, description)
    process_direct(hash["MGREP"], ontology_hash, geo_accession, field_name, field_value, description)
    process_direct(hash["MAPPING"], ontology_hash, geo_accession, field_name, field_value, description, true)
    process_closure(hash["CLOSURE"], ontology_hash, geo_accession, field_name)
  end

  def process_direct(hash, ontology_hash, geo_accession, field_name, field_value, description, mapping=false)
    hash.keys.each do |key|
      current_ncbo_id, term_id = key.split("|")
      save_term('term_id' => "#{ontology_hash[hash[key][:local_ontology_id]]}|#{term_id}", 'ncbo_id' => ontology_hash[hash[key][:local_ontology_id]].to_i, 'term_name' => hash[key][:name])
      save_annotation({'ncbo_id' => ontology_hash[hash[key][:local_ontology_id]].to_i,
                 'ontology_term_id' => "#{ontology_hash[hash[key][:local_ontology_id]]}|#{term_id}",
                 'term_name' => hash[key][:name],
                 'geo_accession' => geo_accession,
                 'field_name' => field_name,
                 'description' => description,
                 'from' => hash[key][:from].to_i,
                 'to' => hash[key][:to].to_i,
                 'synonym' => hash[key][:synonym],
                 'mapping' => mapping})
    end
  end

  def process_closure(hash, ontology_hash, geo_accession, field_name)
    hash.keys.each do |key|
      hash[key].each do |closure|
        current_ncbo_id, term_id = closure[:id].split("|")
        key_current_ncbo_id, key_term_id = key.split("|")
        ncbo_id = ontology_hash[closure[:local_ontology_id]]
        save_term('term_id' => "#{ncbo_id}|#{term_id}", 'ncbo_id' => ncbo_id.to_i, 'term_name' => closure[:name])
        save_closure('geo_accession' => geo_accession, 'field_name' => field_name, 'term_id' => "#{ncbo_id}|#{key_term_id}", 'closure_term' => "#{ncbo_id}|#{term_id}")
      end
    end
  end

  def shutdown
    #DaemonKit.logger.debug("Shutting down #{worker_key}")
    publish(GminerProcessor::SCHEDULER_QUEUE_NAME, {'worker_key' => worker_key, 'command' => 'shutdown'}.to_json)
    listen_queue.unsubscribe do
      exit
    end
  end

  def process_job(params)
    # params = {'email' => email, 'job_id' => job.id, 'geo_accession' => job.geo_accession, 'field' => job.field, 'value' => item.send(job.field), 'description' => item.descriptive_text, 'ncbo_id' => ncbo_id, 'stopwords' => stopwords}
    create_for(params['geo_accession'], params['field'], params['value'], params['description'], params['ncbo_id'], params['ontology_name'], params['stopwords'], params['expand_ontologies'], params['email'])
    #DaemonKit.logger.debug("processing #{params['geo_accession']}:#{params['field']}")
    publish(GminerProcessor::SCHEDULER_QUEUE_NAME, {'worker_key' => worker_key, 'command' => 'finished', 'job_id' => params['job_id']}.to_json)
    rescue NCBOException => ex
      DaemonKit.logger.debug("FAILURE!!!! worker:#{worker_key} job:#{params['job_id']} geo:#{params['geo_accession']} field:#{params['field']} Exception:#{ex.inspect}")
      publish(GminerProcessor::SCHEDULER_QUEUE_NAME, {'worker_key' => worker_key, 'command' => 'failed', 'job_id' => params['job_id']}.to_json)
    ensure
      @processing = false
  end

  def process(msg)
    message = JSON.parse(msg)
    #DaemonKit.logger.debug("#{worker_key} GOT: #{message['command']}")
    case message['command']
      when 'prepare'
        publish(GminerProcessor::SCHEDULER_QUEUE_NAME, {'worker_key' => worker_key, 'command' => 'ready'}.to_json)
      when 'status'
        publish(GminerProcessor::SCHEDULER_QUEUE_NAME, {'worker_key' => worker_key, 'command' => 'status', 'processing' => @processing}.to_json)
      when 'job'
        @processing = true
        publish(GminerProcessor::SCHEDULER_QUEUE_NAME, {'worker_key' => worker_key, 'command' => 'working', 'job_id' => message['job_id']}.to_json)
        process_job(message)
      when 'shutdown'
        shutdown
    end
  end

end
