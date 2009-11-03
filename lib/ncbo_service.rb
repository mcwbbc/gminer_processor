class NCBOService
  include HTTParty
    base_uri 'rest.bioontology.org'
    format :xml

  class << self

    def get_data(text, stopwords, ncbo_ontology_id=nil)
      retried = false
      parameters = {
        "longestOnly" => "false",
        "wholeWordOnly" => "true",
        "stopWords" => stopwords,
        "scored" => "true",
        "ontologiesToExpand" => "#{ncbo_ontology_id}",
        "levelMax" => "10",
        "textToAnnotate"  => "#{text}",
        "format" => "xml"
      }

      parameters.merge!({"ontologiesToKeepInResult" => "#{ncbo_ontology_id}"}) if ncbo_ontology_id

      begin
        data = NCBOService.post("/obs/annotator", :body => parameters)
      rescue EOFError, Errno::ECONNRESET
        raise NCBOException.new('too many connection resets', parameters) if retried
        retried = true
        retry
      rescue Timeout::Error
        DaemonKit.logger.debug("Timeout error retried: #{retried}")
        raise NCBOException.new('consecutive timeout errors', parameters) if retried
        retried = true
        retry
      rescue Exception => e
        DaemonKit.logger.debug("#{e.inspect} -- #{e.message}")
        raise NCBOException.new('invalid XML error', parameters) if retried
        retried = true
        retry
      end
    end

    def result_hash(text, stopwords, ncbo_ontology_id)
      begin
        result = NCBOService.get_data(text, stopwords, ncbo_ontology_id)
        sleep(1) if !result['success']
      end until result['success']
      annotations = result['success']['data']['annotatorResultBean']['annotations']
      hash = NCBOService.generate_hash(annotations)
    end

    def generate_hash(annotations)
      hash = {"MGREP" => {}, "ISA_CLOSURE" => {}, "MAPPING" => {}}
      if annotations && annotations.any?
        bean = annotations["annotationBean"]
        annotation_array = bean.is_a?(Hash) ? [bean] : bean
        hash = annotation_array.inject({"MGREP" => {}, "ISA_CLOSURE" => {}, "MAPPING" => {}}) do |h, annotation|
          concept = annotation["concept"]
          context = annotation["context"]
          h = NCBOService.classify_results(concept, context, h)
          h
        end
      end
      hash
    end

    def classify_results(concept, context, h)
      if context["contextName"] == "MGREP"
        h["MGREP"][concept["localConceptId"].gsub("/","|")] = {:name => concept["preferredName"], :from => context["from"], :to => context["to"]}
      elsif context["contextName"] == "MAPPING"
        # mapping will be treated/processed the same as an mgrep, but with the from,to set to 0 since we can't reference it in the text anyway
        h["MAPPING"][concept["localConceptId"].gsub("/","|")] = {:name => concept["preferredName"], :from => "0", :to => "0"}
      else
        if h["ISA_CLOSURE"][context['concept']["localConceptId"].gsub("/","|")].is_a?(Array)
          h["ISA_CLOSURE"][context['concept']["localConceptId"].gsub("/","|")] << {:name => concept["preferredName"], :id => concept["localConceptId"].gsub("/","|")}
        else
          h["ISA_CLOSURE"][context['concept']["localConceptId"].gsub("/","|")] = [{:name => concept["preferredName"], :id => concept["localConceptId"].gsub("/","|")}]
        end
      end
      h
    end

  end # of class << self

end
