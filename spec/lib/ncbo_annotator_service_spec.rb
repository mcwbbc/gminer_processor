require 'spec_helper'

describe NCBOAnnotatorService do

  describe "generate hash" do
    it "should return empty hashes for no results" do
      results = {"MGREP" => {}, "MAPPING"=>{}, "CLOSURE"=>{}}
      NCBOAnnotatorService.generate_hash([]).should == results
    end

    it "should clean up the returned hash from ncbo if there is one annotation" do
      hash = {'success' =>
              {'data' =>
                {"annotatorResultBean" =>
                  {"text" => "rat strain", "annotations" =>
                    {"annotationBean"=> [
                       {"score"=>"31",
                        "concept"=>
                         {"id"=>"10423999",
                          "localConceptId"=>"44393/MA:0000335",
                          "localOntologyId"=>"44393",
                          "isTopLevel"=>"1",
                          "fullId"=>"http://purl.org/obo/owl/MA#MA_0000335",
                          "preferredName"=>"colon",
                          "synonyms"=>nil,
                          "definitions"=>nil,
                          "semanticTypes"=>
                           {"semanticTypeBean"=>
                             {"id"=>"13363412",
                              "semanticType"=>"T999",
                              "description"=>"NCBO BioPortal concept"}}},
                        "context"=>
                         {"contextName"=>"MAPPING",
                          "isDirect"=>"false",
                          "from"=>"1",
                          "to"=>"5",
                          "mappedConcept"=>
                           {"id"=>"10524934",
                            "localConceptId"=>"44301/UBERON:0001155",
                            "localOntologyId"=>"44301",
                            "isTopLevel"=>"0",
                            "fullId"=>"http://purl.org/obo/owl/UBERON#UBERON_0001155",
                            "preferredName"=>"colon",
                            "synonyms"=>
                             {"string"=>
                               ["posterior intestine - zebrafish",
                                "posterior intestine",
                                "hindgut",
                                "large bowel"]},
                            "definitions"=>nil,
                            "semanticTypes"=>
                             {"semanticTypeBean"=>
                               {"id"=>"13464347",
                                "semanticType"=>"T999",
                                "description"=>"NCBO BioPortal concept"}}},
                          "mappingType"=>"Manual",
                          "class"=>"mappingContextBean"}},
                       {"score"=>"31",
                        "concept"=>
                         {"id"=>"10423999",
                          "localConceptId"=>"44393/MA:0000335",
                          "localOntologyId"=>"44393",
                          "isTopLevel"=>"1",
                          "fullId"=>"http://purl.org/obo/owl/MA#MA_0000335",
                          "preferredName"=>"colon",
                          "synonyms"=>nil,
                          "definitions"=>nil,
                          "semanticTypes"=>
                           {"semanticTypeBean"=>
                             {"id"=>"13363412",
                              "semanticType"=>"T999",
                              "description"=>"NCBO BioPortal concept"}}},
                        "context"=>
                         {"contextName"=>"MGREP",
                          "isDirect"=>"true",
                          "from"=>"1",
                          "to"=>"5",
                          "term"=>
                           {"name"=>"colon",
                            "localConceptId"=>"44393/MA:0000335",
                            "isPreferred"=>"1"},
                          "class"=>"mgrepContextBean"}}
                        ]
                      }}}}}

                results = {"MGREP"=>{"44393|MA:0000335"=>{:local_ontology_id=>"44393", :to=>"5", :from=>"1", :name=>"colon", :synonym => false}},
                "MAPPING"=>{"44393|MA:0000335"=>{:local_ontology_id=>"44393", :to=>"5", :from=>"1", :name=>"colon", :synonym => true}},
                "CLOSURE"=>{}}

      NCBOAnnotatorService.generate_hash(hash['success']['data']['annotatorResultBean']['annotations']).should == results
    end

    it "should clean up the returned hash from ncbo if there are multiple annotations" do
      NCBOAnnotatorService.generate_hash(ANNOTATOR_BIGHASH['success']['data']['annotatorResultBean']['annotations']).should == {"MGREP"=>{"42955|RS:0000704"=>{:name=>"SDJ/Hok", :from=>"1", :to=>"14", :local_ontology_id=>"42955", :synonym=>true}, "42955|RS:0001410"=>{:name=>"NTac:SD", :from=>"1", :to=>"14", :local_ontology_id=>"42955", :synonym=>true}}, "CLOSURE"=>{"42955|RS:0001410"=>[{:name=>"SD", :id=>"42955|RS:0000681", :local_ontology_id=>"42955"}, {:name=>"rat strain", :id=>"42955|RS:0000457", :local_ontology_id=>"42955"}, {:name=>"N:SD", :id=>"42955|RS:0001409", :local_ontology_id=>"42955"}, {:name=>"outbred strain", :id=>"42955|RS:0000462", :local_ontology_id=>"42955"}], "42955|RS:0000704"=>[{:name=>"rat strain", :id=>"42955|RS:0000457", :local_ontology_id=>"42955"}, {:name=>"SDJ", :id=>"42955|RS:0002340", :local_ontology_id=>"42955"}, {:name=>"inbred strain", :id=>"42955|RS:0000765", :local_ontology_id=>"42955"}]}, "MAPPING"=>{"42955|RS:0000704"=>{:name=>"SDJ/Hok", :from=>"1", :to=>"14", :local_ontology_id=>"42955", :synonym=>false}, "42955|RS:0001410"=>{:name=>"NTac:SD", :from=>"1", :to=>"14", :local_ontology_id=>"42955", :synonym=>true}, "42955|RS:0000681"=>{:name=>"SD", :from=>"1", :to=>"14", :local_ontology_id=>"42955", :synonym=>true}, "42955|RS:0000699"=>{:name=>"SD/HsdFcen", :from=>"1", :to=>"14", :local_ontology_id=>"42955", :synonym=>false}, "42955|RS:0000706"=>{:name=>"SDT.ZDF-Leprfa/Jtt", :from=>"1", :to=>"14", :local_ontology_id=>"42955", :synonym=>false}}}
    end
  end

  describe "result_hash" do
    describe "failures" do
      it "should raise an exception without result" do
        NCBOAnnotatorService.should_receive(:get_data).with("word", "stopword", '1150', 'email', "id").and_return(nil)
        lambda {NCBOAnnotatorService.result_hash("word", "stopword", '1150', "id", 'email')}.should raise_error(NCBOException)
      end

      it "should raise an exception without result" do
        hash = {'errorStatus' => {'shortMessage' => 'short', 'longMessage' => 'long'}}
        NCBOAnnotatorService.should_receive(:get_data).with("word", "stopword", '1150', 'email', "id").and_return(hash)
        lambda {NCBOAnnotatorService.result_hash("word", "stopword", '1150', "id", 'email')}.should raise_error(NCBOException)
      end

      it "should raise an exception with success or errorStatus" do
        hash = {'something' => {}}
        NCBOAnnotatorService.should_receive(:get_data).with("word", "stopword", '1150', 'email', "id").and_return(hash)
        lambda {NCBOAnnotatorService.result_hash("word", "stopword", '1150', "id", 'email')}.should raise_error(NCBOException)
      end
    end

    describe "success" do
      describe "with annotations" do
        it "should return the generate hash results and ontology hash" do
          param_hash = {'success' => {'data' => {"annotatorResultBean"=>{"text"=>"rat strain", "annotations"=> ["annotations"], "ontologies" => {'ontologyUsedBean' => "mouse anatomy"}}}}}

          ontology_hash = {"42571"=>"1000"}
          result_hash = {"MGREP"=>{"42571|MA:0000415"=>{:to=>"4", :from=>"1", :local_ontology_id=>"42571", :name=>"lung"}},
                      "MAPPING"=>{"42571|MA:0000415"=>{:to=>"4", :from=>"1", :local_ontology_id=>"42571", :name=>"lung"}},
                      "CLOSURE"=>{"42571|MA:0000415"=>[{:local_ontology_id=>"42571", :name=>"thoracic cavity organ", :id=>"42571|MA:0000557"}, {:local_ontology_id=>"42571", :name=>"thoracic segment organ", :id=>"42571|MA:0000563"}, {:local_ontology_id=>"42571", :name=>"trunk organ", :id=>"42571|MA:0000516"}]}}

          results = [result_hash, ontology_hash]

          NCBOAnnotatorService.should_receive(:generate_ontology_hash).with("mouse anatomy").and_return(ontology_hash)
          NCBOAnnotatorService.should_receive(:get_data).with("word", "stopword", '1150', 'email', "id").and_return(param_hash)
          NCBOAnnotatorService.should_receive(:generate_hash).with(["annotations"]).and_return(result_hash)
          NCBOAnnotatorService.result_hash("word", "stopword", '1150', "id", 'email').should == results
        end
      end

      describe "without annotations" do
        it "should return the generate hash results and an empty hash" do
          hash = {'success' => {'data' => {"annotatorResultBean"=>{"text"=>"rat strain", "annotations"=> []}}}}
          results = [{"MGREP" => {}, "CLOSURE" => {}, "MAPPING" => {}}, {}]
          NCBOAnnotatorService.should_receive(:get_data).with("word", "stopword", '1150', 'email', "id").and_return(hash)
          NCBOAnnotatorService.should_receive(:generate_hash).with([]).and_return({"MGREP" => {}, "CLOSURE" => {}, "MAPPING" => {}})
          NCBOAnnotatorService.result_hash("word", "stopword", '1150', "id", 'email').should == results
        end
      end
    end
  end

  describe "get data" do
    before(:each) do
      @default_params = {'email' => 'user@comp.com',
                         "longestOnly"=>"false",
                         "wholeWordOnly"=>"true",
                         "stopWords"=>"stopwords",
                         "minTermSize"=>"2",
                         "withSynonyms"=>"true",
                         "scored"=>"true",
                         "ontologiesToExpand" => "1150",
                         "ontologiesToKeepInResult" => "1234",
                         "isVirtualOntologyId"=>"true",
                         "levelMax"=>"10",
                         "textToAnnotate"=>"word",
                         "format"=>"xml"} #,"ontologiesToExpand" => "1234"}
    end

    it "should get the xml from ncbo, which is parsed into a hash by httparty" do
      NCBOAnnotatorService.should_receive(:post).with("/obs/annotator", {:body => @default_params}).and_return({:key => "value"})
      NCBOAnnotatorService.get_data("word", "stopwords", '1150', 'user@comp.com', "1234").should == {:key => "value"}
    end

    it "should retry on Errno::ECONNRESET" do
      query = {:body=>@default_params}
      NCBOAnnotatorService.should_receive(:post).with("/obs/annotator", query).once.and_raise(Errno::ECONNRESET)
      NCBOAnnotatorService.should_receive(:post).with("/obs/annotator", query).and_return({:key => "value"})
      NCBOAnnotatorService.get_data("word", "stopwords", '1150', 'user@comp.com', "1234").should == {:key => "value"}
    end

    it "should fail with too many resets" do
      NCBOAnnotatorService.should_receive(:post).with("/obs/annotator", {:body=>@default_params}).twice.and_raise(Errno::ECONNRESET)
      lambda {NCBOAnnotatorService.get_data("word", "stopwords", '1150', 'user@comp.com', "1234")}.should raise_error(NCBOException)
    end

    it "should raise an exception on failure" do
      NCBOAnnotatorService.should_receive(:post).with("/obs/annotator", {:body=>@default_params}).twice.and_raise(Exception)
      lambda {NCBOAnnotatorService.get_data("word", "stopwords", '1150', 'user@comp.com', "1234")}.should raise_error(NCBOException)
    end
  end

end

ANNOTATOR_BIGHASH = {"success"=>
  {"accessedResource"=>"/obs/annotator",
   "accessDate"=>"2011-04-18 12:54:23.21 PDT",
   "data"=>
    {"annotatorResultBean"=>
      {"resultID"=>"OBA_RESULT_b4fc",
       "statistics"=>
        {"statisticsBean"=>
          [{"contextName"=>"MAPPING", "nbAnnotation"=>"25"},
           {"contextName"=>"CLOSURE", "nbAnnotation"=>"7"},
           {"contextName"=>"MGREP", "nbAnnotation"=>"2"}]},
       "parameters"=>
        {"longestOnly"=>"false",
         "wholeWordOnly"=>"true",
         "filterNumber"=>"true",
         "withDefaultStopWords"=>"false",
         "isStopWordsCaseSenstive"=>"false",
         "withSynonyms"=>"true",
         "minTermSize"=>"2",
         "withContext"=>"true",
         "semanticTypes"=>nil,
         "stopWords"=>nil,
         "ontologiesToExpand"=>nil,
         "ontologiesToKeepInResult"=>{"string"=>"1150"},
         "isVirtualOntologyId"=>"true",
         "levelMax"=>"10",
         "mappingTypes"=>nil,
         "textToAnnotate"=>"Sprague Dawley",
         "outputFormat"=>"xml"},
       "annotations"=>
        {"annotationBean"=>
          [{"score"=>"43",
            "concept"=>
             {"id"=>"9548636",
              "localConceptId"=>"42955/RS:0000704",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000704",
              "preferredName"=>"SDJ/Hok",
              "synonyms"=>
               {"string"=>
                 ["RGD ID: 68133", "sprague dawley", "NBRP Rat No. 0045"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449607",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"10844913",
                "localConceptId"=>"44268/p11:birnlex_266",
                "localOntologyId"=>"44268",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-Organism.owl#birnlex_266",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>
                 {"string"=>
                   ["Rats, Sprague Dawley",
                    "Sprague-Dawley rat",
                    "Sprague-Dawley rats"]},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"13808767",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"43",
            "concept"=>
             {"id"=>"9548636",
              "localConceptId"=>"42955/RS:0000704",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000704",
              "preferredName"=>"SDJ/Hok",
              "synonyms"=>
               {"string"=>
                 ["RGD ID: 68133", "sprague dawley", "NBRP Rat No. 0045"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449607",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"4899878",
                "localConceptId"=>"29684/birnlex_266",
                "localOntologyId"=>"29684",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://bioontology.org/projects/ontologies/birnlex#birnlex_266",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>
                 {"string"=>
                   "Rats, Sprague Dawley|Sprague-Dawley rat|Sprague-Dawley rats"},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"7532538",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"43",
            "concept"=>
             {"id"=>"9549341",
              "localConceptId"=>"42955/RS:0001410",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0001410",
              "preferredName"=>"NTac:SD",
              "synonyms"=>
               {"string"=>
                 ["SD/NTac",
                  "Sprague-Dawley ",
                  "Sprague Dawley",
                  "RGD ID: 1566440"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12450312",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"4899878",
                "localConceptId"=>"29684/birnlex_266",
                "localOntologyId"=>"29684",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://bioontology.org/projects/ontologies/birnlex#birnlex_266",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>
                 {"string"=>
                   "Rats, Sprague Dawley|Sprague-Dawley rat|Sprague-Dawley rats"},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"7532538",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"43",
            "concept"=>
             {"id"=>"9548636",
              "localConceptId"=>"42955/RS:0000704",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000704",
              "preferredName"=>"SDJ/Hok",
              "synonyms"=>
               {"string"=>
                 ["RGD ID: 68133", "sprague dawley", "NBRP Rat No. 0045"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449607",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"10844861",
                "localConceptId"=>"44268/p11:birnlex_214",
                "localOntologyId"=>"44268",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-Organism.owl#birnlex_214",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>nil,
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"13808715",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"43",
            "concept"=>
             {"id"=>"9548636",
              "localConceptId"=>"42955/RS:0000704",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000704",
              "preferredName"=>"SDJ/Hok",
              "synonyms"=>
               {"string"=>
                 ["RGD ID: 68133", "sprague dawley", "NBRP Rat No. 0045"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449607",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"4898875",
                "localConceptId"=>"29684/birnlex_214",
                "localOntologyId"=>"29684",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://bioontology.org/projects/ontologies/birnlex#birnlex_214",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>{"string"=>"Sprague_Dawley"},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"7531397",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"43",
            "concept"=>
             {"id"=>"9549341",
              "localConceptId"=>"42955/RS:0001410",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0001410",
              "preferredName"=>"NTac:SD",
              "synonyms"=>
               {"string"=>
                 ["SD/NTac",
                  "Sprague-Dawley ",
                  "Sprague Dawley",
                  "RGD ID: 1566440"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12450312",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"11994318",
                "localConceptId"=>"44757/efo:EFO_0001352",
                "localOntologyId"=>"44757",
                "isTopLevel"=>"0",
                "fullId"=>"http://www.ebi.ac.uk/efo/EFO_0001352",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>nil,
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"15144935",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"43",
            "concept"=>
             {"id"=>"9549341",
              "localConceptId"=>"42955/RS:0001410",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0001410",
              "preferredName"=>"NTac:SD",
              "synonyms"=>
               {"string"=>
                 ["SD/NTac",
                  "Sprague-Dawley ",
                  "Sprague Dawley",
                  "RGD ID: 1566440"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12450312",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"10844861",
                "localConceptId"=>"44268/p11:birnlex_214",
                "localOntologyId"=>"44268",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-Organism.owl#birnlex_214",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>nil,
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"13808715",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"43",
            "concept"=>
             {"id"=>"9548636",
              "localConceptId"=>"42955/RS:0000704",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000704",
              "preferredName"=>"SDJ/Hok",
              "synonyms"=>
               {"string"=>
                 ["RGD ID: 68133", "sprague dawley", "NBRP Rat No. 0045"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449607",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"11994318",
                "localConceptId"=>"44757/efo:EFO_0001352",
                "localOntologyId"=>"44757",
                "isTopLevel"=>"0",
                "fullId"=>"http://www.ebi.ac.uk/efo/EFO_0001352",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>nil,
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"15144935",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"43",
            "concept"=>
             {"id"=>"9549341",
              "localConceptId"=>"42955/RS:0001410",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0001410",
              "preferredName"=>"NTac:SD",
              "synonyms"=>
               {"string"=>
                 ["SD/NTac",
                  "Sprague-Dawley ",
                  "Sprague Dawley",
                  "RGD ID: 1566440"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12450312",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"10844913",
                "localConceptId"=>"44268/p11:birnlex_266",
                "localOntologyId"=>"44268",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-Organism.owl#birnlex_266",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>
                 {"string"=>
                   ["Rats, Sprague Dawley",
                    "Sprague-Dawley rat",
                    "Sprague-Dawley rats"]},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"13808767",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"43",
            "concept"=>
             {"id"=>"9549341",
              "localConceptId"=>"42955/RS:0001410",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0001410",
              "preferredName"=>"NTac:SD",
              "synonyms"=>
               {"string"=>
                 ["SD/NTac",
                  "Sprague-Dawley ",
                  "Sprague Dawley",
                  "RGD ID: 1566440"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12450312",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"4898875",
                "localConceptId"=>"29684/birnlex_214",
                "localOntologyId"=>"29684",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://bioontology.org/projects/ontologies/birnlex#birnlex_214",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>{"string"=>"Sprague_Dawley"},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"7531397",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"43",
            "concept"=>
             {"id"=>"9548636",
              "localConceptId"=>"42955/RS:0000704",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000704",
              "preferredName"=>"SDJ/Hok",
              "synonyms"=>
               {"string"=>
                 ["RGD ID: 68133", "sprague dawley", "NBRP Rat No. 0045"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449607",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MGREP",
              "isDirect"=>"true",
              "from"=>"1",
              "to"=>"14",
              "term"=>
               {"name"=>"sprague dawley",
                "localConceptId"=>"42955/RS:0000704",
                "isPreferred"=>"0"},
              "class"=>"mgrepContextBean"}},
           {"score"=>"43",
            "concept"=>
             {"id"=>"9549341",
              "localConceptId"=>"42955/RS:0001410",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0001410",
              "preferredName"=>"NTac:SD",
              "synonyms"=>
               {"string"=>
                 ["SD/NTac",
                  "Sprague-Dawley ",
                  "Sprague Dawley",
                  "RGD ID: 1566440"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12450312",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MGREP",
              "isDirect"=>"true",
              "from"=>"1",
              "to"=>"14",
              "term"=>
               {"name"=>"Sprague Dawley",
                "localConceptId"=>"42955/RS:0001410",
                "isPreferred"=>"0"},
              "class"=>"mgrepContextBean"}},
           {"score"=>"42",
            "concept"=>
             {"id"=>"9548613",
              "localConceptId"=>"42955/RS:0000681",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000681",
              "preferredName"=>"SD",
              "synonyms"=>
               {"string"=>
                 ["Sprague-Dawley", "Sprague Dawley ", "RGD ID: 70508"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449584",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"11994318",
                "localConceptId"=>"44757/efo:EFO_0001352",
                "localOntologyId"=>"44757",
                "isTopLevel"=>"0",
                "fullId"=>"http://www.ebi.ac.uk/efo/EFO_0001352",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>nil,
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"15144935",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"42",
            "concept"=>
             {"id"=>"9548613",
              "localConceptId"=>"42955/RS:0000681",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000681",
              "preferredName"=>"SD",
              "synonyms"=>
               {"string"=>
                 ["Sprague-Dawley", "Sprague Dawley ", "RGD ID: 70508"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449584",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"4898875",
                "localConceptId"=>"29684/birnlex_214",
                "localOntologyId"=>"29684",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://bioontology.org/projects/ontologies/birnlex#birnlex_214",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>{"string"=>"Sprague_Dawley"},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"7531397",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"42",
            "concept"=>
             {"id"=>"9548613",
              "localConceptId"=>"42955/RS:0000681",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000681",
              "preferredName"=>"SD",
              "synonyms"=>
               {"string"=>
                 ["Sprague-Dawley", "Sprague Dawley ", "RGD ID: 70508"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449584",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"4899878",
                "localConceptId"=>"29684/birnlex_266",
                "localOntologyId"=>"29684",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://bioontology.org/projects/ontologies/birnlex#birnlex_266",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>
                 {"string"=>
                   "Rats, Sprague Dawley|Sprague-Dawley rat|Sprague-Dawley rats"},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"7532538",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"42",
            "concept"=>
             {"id"=>"9548613",
              "localConceptId"=>"42955/RS:0000681",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000681",
              "preferredName"=>"SD",
              "synonyms"=>
               {"string"=>
                 ["Sprague-Dawley", "Sprague Dawley ", "RGD ID: 70508"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449584",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"10844861",
                "localConceptId"=>"44268/p11:birnlex_214",
                "localOntologyId"=>"44268",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-Organism.owl#birnlex_214",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>nil,
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"13808715",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"42",
            "concept"=>
             {"id"=>"9548613",
              "localConceptId"=>"42955/RS:0000681",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000681",
              "preferredName"=>"SD",
              "synonyms"=>
               {"string"=>
                 ["Sprague-Dawley", "Sprague Dawley ", "RGD ID: 70508"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449584",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"10844913",
                "localConceptId"=>"44268/p11:birnlex_266",
                "localOntologyId"=>"44268",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-Organism.owl#birnlex_266",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>
                 {"string"=>
                   ["Rats, Sprague Dawley",
                    "Sprague-Dawley rat",
                    "Sprague-Dawley rats"]},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"13808767",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"42",
            "concept"=>
             {"id"=>"9548613",
              "localConceptId"=>"42955/RS:0000681",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000681",
              "preferredName"=>"SD",
              "synonyms"=>
               {"string"=>
                 ["Sprague-Dawley", "Sprague Dawley ", "RGD ID: 70508"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449584",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"CLOSURE",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "concept"=>
               {"id"=>"9549341",
                "localConceptId"=>"42955/RS:0001410",
                "localOntologyId"=>"42955",
                "isTopLevel"=>"0",
                "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0001410",
                "preferredName"=>"NTac:SD",
                "synonyms"=>
                 {"string"=>
                   ["SD/NTac",
                    "Sprague-Dawley ",
                    "Sprague Dawley",
                    "RGD ID: 1566440"]},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"12450312",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "level"=>"2",
              "class"=>"isaContextBean"}},
           {"score"=>"35",
            "concept"=>
             {"id"=>"9548631",
              "localConceptId"=>"42955/RS:0000699",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000699",
              "preferredName"=>"SD/HsdFcen",
              "synonyms"=>
               {"string"=>
                 ["Sprague-Dawley", "Sprague Dawley ", "RGD ID: 1302359"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449602",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"10844913",
                "localConceptId"=>"44268/p11:birnlex_266",
                "localOntologyId"=>"44268",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-Organism.owl#birnlex_266",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>
                 {"string"=>
                   ["Rats, Sprague Dawley",
                    "Sprague-Dawley rat",
                    "Sprague-Dawley rats"]},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"13808767",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"35",
            "concept"=>
             {"id"=>"9548631",
              "localConceptId"=>"42955/RS:0000699",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000699",
              "preferredName"=>"SD/HsdFcen",
              "synonyms"=>
               {"string"=>
                 ["Sprague-Dawley", "Sprague Dawley ", "RGD ID: 1302359"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449602",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"4898875",
                "localConceptId"=>"29684/birnlex_214",
                "localOntologyId"=>"29684",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://bioontology.org/projects/ontologies/birnlex#birnlex_214",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>{"string"=>"Sprague_Dawley"},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"7531397",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"35",
            "concept"=>
             {"id"=>"9548638",
              "localConceptId"=>"42955/RS:0000706",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000706",
              "preferredName"=>"SDT.ZDF-Leprfa/Jtt",
              "synonyms"=>
               {"string"=>
                 ["SDT fatty", "SDT.Cg-Leprfa/Jtp", "RGD ID: 2314027"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449609",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"10844913",
                "localConceptId"=>"44268/p11:birnlex_266",
                "localOntologyId"=>"44268",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-Organism.owl#birnlex_266",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>
                 {"string"=>
                   ["Rats, Sprague Dawley",
                    "Sprague-Dawley rat",
                    "Sprague-Dawley rats"]},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"13808767",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"35",
            "concept"=>
             {"id"=>"9548638",
              "localConceptId"=>"42955/RS:0000706",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000706",
              "preferredName"=>"SDT.ZDF-Leprfa/Jtt",
              "synonyms"=>
               {"string"=>
                 ["SDT fatty", "SDT.Cg-Leprfa/Jtp", "RGD ID: 2314027"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449609",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"4899878",
                "localConceptId"=>"29684/birnlex_266",
                "localOntologyId"=>"29684",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://bioontology.org/projects/ontologies/birnlex#birnlex_266",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>
                 {"string"=>
                   "Rats, Sprague Dawley|Sprague-Dawley rat|Sprague-Dawley rats"},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"7532538",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"35",
            "concept"=>
             {"id"=>"9548631",
              "localConceptId"=>"42955/RS:0000699",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000699",
              "preferredName"=>"SD/HsdFcen",
              "synonyms"=>
               {"string"=>
                 ["Sprague-Dawley", "Sprague Dawley ", "RGD ID: 1302359"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449602",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"4899878",
                "localConceptId"=>"29684/birnlex_266",
                "localOntologyId"=>"29684",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://bioontology.org/projects/ontologies/birnlex#birnlex_266",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>
                 {"string"=>
                   "Rats, Sprague Dawley|Sprague-Dawley rat|Sprague-Dawley rats"},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"7532538",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"35",
            "concept"=>
             {"id"=>"9548631",
              "localConceptId"=>"42955/RS:0000699",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000699",
              "preferredName"=>"SD/HsdFcen",
              "synonyms"=>
               {"string"=>
                 ["Sprague-Dawley", "Sprague Dawley ", "RGD ID: 1302359"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449602",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"10844861",
                "localConceptId"=>"44268/p11:birnlex_214",
                "localOntologyId"=>"44268",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-Organism.owl#birnlex_214",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>nil,
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"13808715",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"35",
            "concept"=>
             {"id"=>"9548638",
              "localConceptId"=>"42955/RS:0000706",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000706",
              "preferredName"=>"SDT.ZDF-Leprfa/Jtt",
              "synonyms"=>
               {"string"=>
                 ["SDT fatty", "SDT.Cg-Leprfa/Jtp", "RGD ID: 2314027"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449609",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"10844861",
                "localConceptId"=>"44268/p11:birnlex_214",
                "localOntologyId"=>"44268",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://ontology.neuinfo.org/NIF/BiomaterialEntities/NIF-Organism.owl#birnlex_214",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>nil,
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"13808715",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"35",
            "concept"=>
             {"id"=>"9548631",
              "localConceptId"=>"42955/RS:0000699",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000699",
              "preferredName"=>"SD/HsdFcen",
              "synonyms"=>
               {"string"=>
                 ["Sprague-Dawley", "Sprague Dawley ", "RGD ID: 1302359"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449602",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"11994318",
                "localConceptId"=>"44757/efo:EFO_0001352",
                "localOntologyId"=>"44757",
                "isTopLevel"=>"0",
                "fullId"=>"http://www.ebi.ac.uk/efo/EFO_0001352",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>nil,
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"15144935",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"35",
            "concept"=>
             {"id"=>"9548638",
              "localConceptId"=>"42955/RS:0000706",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000706",
              "preferredName"=>"SDT.ZDF-Leprfa/Jtt",
              "synonyms"=>
               {"string"=>
                 ["SDT fatty", "SDT.Cg-Leprfa/Jtp", "RGD ID: 2314027"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449609",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"4898875",
                "localConceptId"=>"29684/birnlex_214",
                "localOntologyId"=>"29684",
                "isTopLevel"=>"0",
                "fullId"=>
                 "http://bioontology.org/projects/ontologies/birnlex#birnlex_214",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>{"string"=>"Sprague_Dawley"},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"7531397",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"35",
            "concept"=>
             {"id"=>"9548638",
              "localConceptId"=>"42955/RS:0000706",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000706",
              "preferredName"=>"SDT.ZDF-Leprfa/Jtt",
              "synonyms"=>
               {"string"=>
                 ["SDT fatty", "SDT.Cg-Leprfa/Jtp", "RGD ID: 2314027"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449609",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"MAPPING",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "mappedConcept"=>
               {"id"=>"11994318",
                "localConceptId"=>"44757/efo:EFO_0001352",
                "localOntologyId"=>"44757",
                "isTopLevel"=>"0",
                "fullId"=>"http://www.ebi.ac.uk/efo/EFO_0001352",
                "preferredName"=>"Sprague Dawley",
                "synonyms"=>nil,
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"15144935",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "mappingType"=>"Automatic",
              "class"=>"mappingContextBean"}},
           {"score"=>"11",
            "concept"=>
             {"id"=>"9548389",
              "localConceptId"=>"42955/RS:0000457",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"1",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000457",
              "preferredName"=>"rat strain",
              "synonyms"=>nil,
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449360",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"CLOSURE",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "concept"=>
               {"id"=>"9549341",
                "localConceptId"=>"42955/RS:0001410",
                "localOntologyId"=>"42955",
                "isTopLevel"=>"0",
                "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0001410",
                "preferredName"=>"NTac:SD",
                "synonyms"=>
                 {"string"=>
                   ["SD/NTac",
                    "Sprague-Dawley ",
                    "Sprague Dawley",
                    "RGD ID: 1566440"]},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"12450312",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "level"=>"4",
              "class"=>"isaContextBean"}},
           {"score"=>"11",
            "concept"=>
             {"id"=>"9548389",
              "localConceptId"=>"42955/RS:0000457",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"1",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000457",
              "preferredName"=>"rat strain",
              "synonyms"=>nil,
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449360",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"CLOSURE",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "concept"=>
               {"id"=>"9548636",
                "localConceptId"=>"42955/RS:0000704",
                "localOntologyId"=>"42955",
                "isTopLevel"=>"0",
                "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000704",
                "preferredName"=>"SDJ/Hok",
                "synonyms"=>
                 {"string"=>
                   ["RGD ID: 68133", "sprague dawley", "NBRP Rat No. 0045"]},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"12449607",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "level"=>"3",
              "class"=>"isaContextBean"}},
           {"score"=>"9",
            "concept"=>
             {"id"=>"9549340",
              "localConceptId"=>"42955/RS:0001409",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0001409",
              "preferredName"=>"N:SD",
              "synonyms"=>
               {"string"=>
                 ["SD/N",
                  "Sprague Dawley ",
                  "RRRC:0239",
                  "Sprague-Dawley ",
                  "SDN:SD"]},
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12450311",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"CLOSURE",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "concept"=>
               {"id"=>"9549341",
                "localConceptId"=>"42955/RS:0001410",
                "localOntologyId"=>"42955",
                "isTopLevel"=>"0",
                "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0001410",
                "preferredName"=>"NTac:SD",
                "synonyms"=>
                 {"string"=>
                   ["SD/NTac",
                    "Sprague-Dawley ",
                    "Sprague Dawley",
                    "RGD ID: 1566440"]},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"12450312",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "level"=>"1",
              "class"=>"isaContextBean"}},
           {"score"=>"9",
            "concept"=>
             {"id"=>"9550271",
              "localConceptId"=>"42955/RS:0002340",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0002340",
              "preferredName"=>"SDJ",
              "synonyms"=>nil,
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12451242",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"CLOSURE",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "concept"=>
               {"id"=>"9548636",
                "localConceptId"=>"42955/RS:0000704",
                "localOntologyId"=>"42955",
                "isTopLevel"=>"0",
                "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000704",
                "preferredName"=>"SDJ/Hok",
                "synonyms"=>
                 {"string"=>
                   ["RGD ID: 68133", "sprague dawley", "NBRP Rat No. 0045"]},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"12449607",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "level"=>"1",
              "class"=>"isaContextBean"}},
           {"score"=>"7",
            "concept"=>
             {"id"=>"9548697",
              "localConceptId"=>"42955/RS:0000765",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000765",
              "preferredName"=>"inbred strain",
              "synonyms"=>nil,
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449668",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"CLOSURE",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "concept"=>
               {"id"=>"9548636",
                "localConceptId"=>"42955/RS:0000704",
                "localOntologyId"=>"42955",
                "isTopLevel"=>"0",
                "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000704",
                "preferredName"=>"SDJ/Hok",
                "synonyms"=>
                 {"string"=>
                   ["RGD ID: 68133", "sprague dawley", "NBRP Rat No. 0045"]},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"12449607",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "level"=>"2",
              "class"=>"isaContextBean"}},
           {"score"=>"6",
            "concept"=>
             {"id"=>"9548394",
              "localConceptId"=>"42955/RS:0000462",
              "localOntologyId"=>"42955",
              "isTopLevel"=>"0",
              "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0000462",
              "preferredName"=>"outbred strain",
              "synonyms"=>nil,
              "definitions"=>nil,
              "semanticTypes"=>
               {"semanticTypeBean"=>
                 {"id"=>"12449365",
                  "semanticType"=>"T999",
                  "description"=>"NCBO BioPortal concept"}}},
            "context"=>
             {"contextName"=>"CLOSURE",
              "isDirect"=>"false",
              "from"=>"1",
              "to"=>"14",
              "concept"=>
               {"id"=>"9549341",
                "localConceptId"=>"42955/RS:0001410",
                "localOntologyId"=>"42955",
                "isTopLevel"=>"0",
                "fullId"=>"http://purl.bioontology.org/ontology/RS/RS_0001410",
                "preferredName"=>"NTac:SD",
                "synonyms"=>
                 {"string"=>
                   ["SD/NTac",
                    "Sprague-Dawley ",
                    "Sprague Dawley",
                    "RGD ID: 1566440"]},
                "definitions"=>nil,
                "semanticTypes"=>
                 {"semanticTypeBean"=>
                   {"id"=>"12450312",
                    "semanticType"=>"T999",
                    "description"=>"NCBO BioPortal concept"}}},
              "level"=>"3",
              "class"=>"isaContextBean"}}]},
       "ontologies"=>
        {"ontologyUsedBean"=>
          {"localOntologyId"=>"42955",
           "name"=>"Rat Strain Ontology",
           "version"=>"2.1",
           "virtualOntologyId"=>"1150",
           "nbAnnotation"=>"34",
           "score"=>"1171"}}}}}}
