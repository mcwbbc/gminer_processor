require 'spec_helper'

describe GminerProcessor do

  before(:each) do
    @queue = mock("queue")
    @lq = mock("listen_queue")
    @queue.stub!(:bind).and_return(@lq)
    @mq = mock("message_queue")
    @mq.stub!(:queue).and_return(@queue)
    @mq.stub!(:topic).and_return("")
    @p = GminerProcessor.new(@mq)
    @p.stub!(:worker_key).and_return("1234")
  end

  describe "process" do
    it "should send prepare" do
      @message = {'command' => 'prepare'}
      JSON.should_receive(:parse).with(@message).and_return(@message)
      @p.should_receive(:publish).with("gminer-scheduler", "{\"worker_key\":\"1234\",\"command\":\"ready\"}").and_return(true)
      @p.process(@message)
    end

    it "should send status" do
      @message = {'command' => 'status'}
      JSON.should_receive(:parse).with(@message).and_return(@message)
      @p.should_receive(:publish).with("gminer-scheduler", "{\"worker_key\":\"1234\",\"command\":\"status\",\"processing\":false}").and_return(true)
      @p.process(@message)
    end

    it "should send working" do
      @message = {'command' => 'job', 'job_id' => "1"}
      JSON.should_receive(:parse).with(@message).and_return(@message)
      @p.should_receive(:publish).with("gminer-scheduler", "{\"worker_key\":\"1234\",\"command\":\"working\",\"job_id\":\"1\"}").and_return(true)
      @p.should_receive(:process_job).with(@message)
      @p.process(@message)
      @p.processing.should == true
    end

    it "should shutdown" do
      @message = {'command' => 'shutdown'}
      JSON.should_receive(:parse).with(@message).and_return(@message)
      @p.should_receive(:shutdown)
      @p.process(@message)
    end
  end

  describe "process job" do
    before(:each) do
      @hash = {'email' => 'user@comp.com', 'geo_accession' => "geo", 'field' => "field", 'value' => "value", 'description' => "desc", 'ncbo_id' => "ncbo_id", 'job_id' => 1, 'stopwords' => 'stopwords', 'expand_ontologies' => '1150', 'ontology_name' => 'mouse anatomy'}
    end

    it "should call create for and send a finished message" do
      @p.should_receive(:create_for).with("geo", "field", "value", "desc", "ncbo_id", 'mouse anatomy', "stopwords", "1150", 'user@comp.com').and_return(true)
      @p.should_receive(:publish).with("gminer-scheduler", "{\"worker_key\":\"1234\",\"command\":\"finished\",\"job_id\":1}").and_return(true)
      @p.process_job(@hash).should be_true
      @p.processing.should == false
    end

    it "should publish a failure message on fail" do
      @p.should_receive(:create_for).with("geo", "field", "value", "desc", "ncbo_id", 'mouse anatomy', "stopwords", '1150', 'user@comp.com').and_raise(NCBOException.new("error", "params"))
      @p.should_receive(:publish).with("gminer-scheduler", "{\"worker_key\":\"1234\",\"command\":\"failed\",\"job_id\":1}").and_return(true)
      @p.process_job(@hash).should be_true
      @p.processing.should == false
    end
  end

  describe "shutdown" do
    it "should send a message and quit" do
      @p.should_receive(:publish).with("gminer-scheduler", "{\"worker_key\":\"1234\",\"command\":\"shutdown\"}").and_return(true)
      @p.should_receive(:exit).and_return(true)
      @queue.should_receive(:unsubscribe).and_yield()
      @p.shutdown.should be_true
    end
  end

  describe "create for" do
    it "should get the information from NCBO and process it" do
      NCBOAnnotatorService.should_receive(:result_hash).with("field_value", "stopwords", '1150', "ncbo_id", 'user@comp.com').and_return(["term_hash", 'ontology_hash'])
      @p.should_receive(:process_ncbo_results).with("term_hash", 'ontology_hash', "GSM1234", "field_name", "field_value", "description").and_return(true)
      @p.create_for("GSM1234", "field_name", "field_value", "description", "ncbo_id", 'ontology_name', "stopwords", '1150', 'user@comp.com').should be_true
    end
  end

  describe "process ncbo results" do
    it "should process the hash" do
      @p.should_receive(:process_direct).with({:mg => "value"}, {'1234' => '1000'}, "GPL1234", "field_name", "field_value", "description").and_return(true)
      @p.should_receive(:process_direct).with({:ma => "value"}, {'1234' => '1000'}, "GPL1234", "field_name", "field_value", "description", true).and_return(true)
      @p.should_receive(:process_closure).with({:cl => "value"}, {'1234' => '1000'}, "GPL1234", "field_name").and_return(true)
      @p.process_ncbo_results({"MGREP" => {:mg => "value"}, "MAPPING" => {:ma => "value"}, "CLOSURE" => {:cl => "value"}}, {'1234' => '1000'}, "GPL1234", "field_name", "field_value", "description")
    end
  end

  describe "process closure" do
    it "should create annotation closures" do
      hash = {"42571|MA:0000415"=>[
                        {:local_ontology_id=>"42571", :name=>"thoracic cavity organ", :id=>"42571|MA:0000557"},
                        {:local_ontology_id=>"42571", :name=>"thoracic segment organ", :id=>"42571|MA:0000563"}]}

      ontology_hash = {"42571"=>"1000"}

      @p.should_receive(:save_term).with('term_id' => "1000|MA:0000557", 'ncbo_id' => 1000, 'term_name' => "thoracic cavity organ").and_return(true)
      @p.should_receive(:save_closure).with('geo_accession' => "GSM1234", 'field_name' => 'field_name', 'term_id' => "1000|MA:0000415", 'closure_term' => "1000|MA:0000557").and_return(true)

      @p.should_receive(:save_term).with('term_id' => "1000|MA:0000563", 'ncbo_id' => 1000, 'term_name' => "thoracic segment organ").and_return(true)
      @p.should_receive(:save_closure).with('geo_accession' => "GSM1234", 'field_name' => 'field_name', 'term_id' => "1000|MA:0000415", 'closure_term' => "1000|MA:0000563").and_return(true)

      @p.process_closure(hash, ontology_hash, "GSM1234", "field_name")
    end
  end

  describe "process direct" do
    it "should create annotations" do
      ontology_hash = {"42571"=>"1000"}
      hash = {"42571|MA:0000415"=>{:to=>"4", :from=>"1", :local_ontology_id=>"42571", :name=>"lung", :synonym => false}}

      @p.should_receive(:save_term).with('term_id' => "1000|MA:0000415", 'ncbo_id' => 1000, 'term_name' => "lung").and_return(true)
      @p.should_receive(:save_annotation).with({"from"=>1, "geo_accession"=>"GSM1234", "to"=>4, "ncbo_id"=>1000, "term_name"=>"lung", "field_name"=>"field_name", "ontology_term_id"=>"1000|MA:0000415", 'description' => 'description', 'mapping' => false, 'synonym' => false})
      @p.process_direct(hash, ontology_hash, "GSM1234", "field_name", "field_value", "description")
    end

    it "should do nothing if we didn't get back any results" do
      hash = {}
      ontology_hash = {}
      @p.process_direct(hash, ontology_hash, "GSM1234", "field_name", "field_value", "description")
    end
  end

  describe "save term" do
    it "should send the term message" do
      @p.should_receive(:databaser_message).with("{\"command\":\"saveterm\",\"key\":\"value\"}").and_return(true)
      @p.save_term({'key' => 'value'})
    end
  end

  describe "save annotation" do
    it "should send the annotation message" do
      @p.should_receive(:databaser_message).with("{\"command\":\"saveannotation\",\"key\":\"value\"}").and_return(true)
      @p.save_annotation({'key' => 'value'})
    end
  end

  describe "save closure" do
    it "should send the closure message" do
      @p.should_receive(:databaser_message).with("{\"command\":\"saveclosure\",\"key\":\"value\"}").and_return(true)
      @p.save_closure({'key' => 'value'})
    end
  end

  describe "databaser_message" do
    it "should send the databaser_message" do
      @p.databaser_queue.should_receive(:publish).with("message").and_return(true)
      @p.databaser_message("message")
    end
  end

  describe "new" do
    it "should use the queue" do
      @p.mq.should == @mq
    end
  end

end
