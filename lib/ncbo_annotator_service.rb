class NCBOAnnotatorService
  include HTTParty
    base_uri 'rest.bioontology.org'
    format :xml
    headers ({'User-Agent' => 'MCW GMiner-Annotator Client'})
  class << self

    def get_data(text, stopwords, expand_ontologies, email, ncbo_ontology_id)
      retried = false
      parameters = {
        "email" => email,
        "longestOnly" => "false",
        "wholeWordOnly" => "true",
        "stopWords" => stopwords,
        "minTermSize" => "2",
        "withSynonyms" => "true",
        "scored" => "true",
        "ontologiesToExpand" => "#{expand_ontologies}",
        "ontologiesToKeepInResult" => "#{ncbo_ontology_id}",
        "isVirtualOntologyId" => "true",
        "levelMax" => "10",
        "textToAnnotate"  => "#{text}",
        "format" => "xml"
      }

      begin
        data = NCBOAnnotatorService.post("/obs/annotator", :body => parameters)
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
        DaemonKit.logger.debug("#{e.inspect} -- #{e.message} -- DATA: #{data}")
        raise NCBOException.new('invalid XML error', parameters) if retried
        retried = true
        retry
      end
    end

    def result_hash(text, stopwords, expand_ontologies, ncbo_ontology_id, email)
      result = NCBOAnnotatorService.get_data(text, stopwords, expand_ontologies, email, ncbo_ontology_id)
      if result && result['success']
        annotations = result['success']['data']['annotatorResultBean']['annotations']
        ontology_hash = annotations.blank? ? {} : generate_ontology_hash(result['success']['data']['annotatorResultBean']['ontologies']['ontologyUsedBean'])
        return [NCBOAnnotatorService.generate_hash(annotations), ontology_hash]
      elsif result && result['errorStatus']
        raise NCBOException.new(result['errorStatus']['shortMessage'], result['errorStatus']['longMessage'])
      else
        raise NCBOException.new("Unknown NCBO Error", result)
      end
    end

    def generate_ontology_hash(ontologies)
      ontologies = ontologies.is_a?(Array) ? ontologies : [ontologies]
      hash = ontologies.inject({}) do |h, ontology|
        h[ontology['localOntologyId']] = ontology['virtualOntologyId']
        h
      end
    end

    def generate_hash(annotations)
      hash = {"MGREP" => {}, "CLOSURE" => {}, "MAPPING" => {}}
      if annotations && annotations.any?
        bean = annotations["annotationBean"]
        annotation_array = bean.is_a?(Hash) ? [bean] : bean
        hash = annotation_array.inject({"MGREP" => {}, "CLOSURE" => {}, "MAPPING" => {}}) do |h, annotation|
          concept = annotation["concept"]
          context = annotation["context"]
          h = NCBOAnnotatorService.classify_results(concept, context, h)
          h
        end
      end
      hash
    end

    def classify_results(concept, context, h)
      if context["contextName"] == "MGREP"
        h["MGREP"][concept["localConceptId"].gsub("/","|")] = {:name => concept["preferredName"], :from => context["from"], :to => context["to"], :local_ontology_id => concept['localOntologyId'], :synonym => !!(concept['synonyms'] && concept['synonyms']['string'] && !concept['synonyms']['string'].blank?)}
      elsif context["contextName"] == "MAPPING"
        h["MAPPING"][concept["localConceptId"].gsub("/","|")] = {:name => concept["preferredName"], :from => context["from"], :to => context["to"], :local_ontology_id => concept['localOntologyId'], :synonym => !!(context['mappedConcept']['synonyms'] && context['mappedConcept']['synonyms']['string'] && !context['mappedConcept']['synonyms']['string'].blank?)}
      else
        if h["CLOSURE"][context['concept']["localConceptId"].gsub("/","|")].is_a?(Array)
          h["CLOSURE"][context['concept']["localConceptId"].gsub("/","|")] << {:name => concept["preferredName"], :id => concept["localConceptId"].gsub("/","|"), :local_ontology_id => concept['localOntologyId']}
          h["CLOSURE"][context['concept']["localConceptId"].gsub("/","|")].uniq!
        else
          h["CLOSURE"][context['concept']["localConceptId"].gsub("/","|")] = [{:name => concept["preferredName"], :id => concept["localConceptId"].gsub("/","|"), :local_ontology_id => concept['localOntologyId']}]
        end
      end
      h
    end

  end # of class << self

end
