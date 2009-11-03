require File.dirname(__FILE__) + '/../spec_helper'

describe GminerProcessor do

  before(:each) do
    @mq = mock("message_queue")
    @p = GminerProcessor.new(@mq)
    @p.stub!(:worker_key).and_return("1234")
  end

  describe "process" do
    it "should send prepare" do
      @message = {'command' => 'prepare'}
      JSON.should_receive(:parse).with(@message).and_return(@message)
      @p.should_receive(:publish).with("gminer-scheduler", "{\"command\":\"ready\",\"worker_key\":\"1234\"}").and_return(true)
      @p.process(@message)
    end

    it "should send working" do
      @message = {'command' => 'job', 'job_id' => "1"}
      JSON.should_receive(:parse).with(@message).and_return(@message)
      @p.should_receive(:publish).with("gminer-scheduler", "{\"command\":\"working\",\"job_id\":\"1\",\"worker_key\":\"1234\"}").and_return(true)
      @p.should_receive(:process_job).with(@message)
      @p.process(@message)
    end

    it "should shutdown" do
      @message = {'command' => 'shutdown'}
      JSON.should_receive(:parse).with(@message).and_return(@message)
      @p.should_receive(:shutdown)
      @p.process(@message)
    end
  end

  describe "process job" do
    it "should call create for and send a finished message" do
      @p.should_receive(:create_for).with("geo", "field", "value", "desc", "ncbo_id", "current_ncbo_id", "stopwords").and_return(true)
      @p.should_receive(:publish).with("gminer-scheduler", "{\"command\":\"finished\",\"job_id\":1,\"worker_key\":\"1234\"}").and_return(true)
      hash = {'geo_accession' => "geo", 'field' => "field", 'value' => "value", 'description' => "desc", 'ncbo_id' => "ncbo_id", 'job_id' => 1, 'stopwords' => 'stopwords', 'current_ncbo_id' => 'current_ncbo_id'}
      @p.process_job(hash).should be_true
    end

    it "should publish a failure message on fail" do
      @p.should_receive(:create_for).with("geo", "field", "value", "desc", "ncbo_id", "current_ncbo_id", "stopwords").and_raise(NCBOException.new("error", "params"))
      @p.should_receive(:publish).with("gminer-scheduler", "{\"command\":\"failed\",\"job_id\":1,\"worker_key\":\"1234\"}").and_return(true)
      hash = {'geo_accession' => "geo", 'field' => "field", 'value' => "value", 'description' => "desc", 'ncbo_id' => "ncbo_id", 'job_id' => 1, 'stopwords' => 'stopwords', 'current_ncbo_id' => 'current_ncbo_id'}
      @p.process_job(hash).should be_true
    end
  end

  describe "shutdown" do
    it "should send a message and quit" do
      @p.should_receive(:publish).with("gminer-scheduler", "{\"command\":\"shutdown\",\"worker_key\":\"1234\"}").and_return(true)
      @p.should_receive(:exit).and_return(true)
      @p.shutdown.should be_true
    end
  end

  describe "create for" do
    it "should get the information from NCBO and process it" do
      NCBOService.should_receive(:result_hash).with("field_value", "stopwords", "current_ncbo_id").and_return("hash")
      @p.should_receive(:process_ncbo_results).with("hash", "GSM1234", "field_name", "description", "ncbo_id").and_return(true)
      @p.create_for("GSM1234", "field_name", "field_value", "description", "ncbo_id", "current_ncbo_id", "stopwords").should be_true
    end
  end

  describe "process ncbo results" do
    it "should process the hash" do
      @p.should_receive(:process_direct).with({:mg => "value"}, "GPL1234", "summary", "desc", "ncbo_id").and_return(true)
      @p.should_receive(:process_direct).with({:ma => "value"}, "GPL1234", "summary", "desc", "ncbo_id").and_return(true)
      @p.should_receive(:process_closure).with({:cl => "value"}, "GPL1234", "summary", "ncbo_id").and_return(true)
      @p.process_ncbo_results({"MGREP" => {:mg => "value"}, "MAPPING" => {:ma => "value"}, "ISA_CLOSURE" => {:cl => "value"}}, "GPL1234", "summary", "desc", "ncbo_id")
    end
  end

  describe "process closure" do
    it "should create annotation closures" do
      hash = {
        "MSH|C0003062"=> [
          {:name => "MeSH Descriptors", :id => "MSH|C1256739"}
          ],
        "MSH|C0034721"=> [
          {:name => "Animals", :id => "MSH|C0003062"},
          ]
      }
      @p.should_receive(:save_term).with('term_id' => "ncbo_id|C1256739", 'ncbo_id' => "ncbo_id", 'term_name' => "MeSH Descriptors").and_return(true)
      @p.should_receive(:save_closure).with('geo_accession' => "GSM1234", 'field_name' => 'fname', 'term_id' => "ncbo_id|C0003062", 'closure_term' => "ncbo_id|C1256739").and_return(true)

      @p.should_receive(:save_term).with('term_id' => "ncbo_id|C0003062", 'ncbo_id' => "ncbo_id", 'term_name' => "Animals").and_return(true)
      @p.should_receive(:save_closure).with('geo_accession' => "GSM1234", 'field_name' => 'fname', 'term_id' => "ncbo_id|C0034721", 'closure_term' => "ncbo_id|C0003062").and_return(true)

      @p.process_closure(hash, "GSM1234", "fname", "ncbo_id")
    end
  end

  describe "process direct" do
    it "should create annotations" do
      hash = {
        "MSH|C0003062"=>{:name=>"Animals", :from => "19", :to => "25"}
      }
      @p.should_receive(:save_term).with('term_id' => "ncbo_id|C0003062", 'ncbo_id' => "ncbo_id", 'term_name' => "Animals").and_return(true)
      @p.should_receive(:save_annotation).with('geo_accession' => "GSM1234", 'field_name' => "fname", 'ncbo_id' => "ncbo_id", 'ontology_term_id' => "ncbo_id|C0003062", 'text_start' => "19", 'text_end' => "25", 'description' => "desc")
      @p.process_direct(hash, "GSM1234", "fname", "desc", "ncbo_id")
    end

    it "should create an empty annotation if we didn't get back any results" do
      hash = {}
      @p.should_receive(:save_annotation).with('geo_accession' => "GSM1234", 'field_name' => "fname", 'ncbo_id' => "none", 'ontology_term_id' => "none", 'text_start' => "0", 'text_end' => "0", 'description' => "")
      @p.process_direct(hash, "GSM1234", "fname", "desc", "ncbo_id")
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
      @p.should_receive(:publish).with("gminer-databaser", "message").and_return(true)
      @p.databaser_message("message")
    end
  end

  describe "new" do
    it "should use the queue" do
      @p.mq.should == @mq
    end
  end
  
end
