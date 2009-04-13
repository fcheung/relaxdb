require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB do

  before(:all) do
    RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "spec_doc"
    @server = RelaxDB::Server.new("localhost", 5984, RelaxDB::MemoryStore.new)
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec" rescue "ok"
    RelaxDB.use_db "relaxdb_spec"    
  end
        
  describe "GET" do
    
    it "should raise a HTTP_404 for a non existant doc" do
      lambda do
        @server.get "/relaxdb_spec/foo"
      end.should raise_error(RelaxDB::HTTP_404)
    end

    it "should raise a RuntimeError for non specific errors" do
      lambda do
        @server.get "/relaxdb_spec/_design/spec_doc/_view?fail=true"
      end.should raise_error(RuntimeError)
    end
    
    it "should store results in the cache" do
      a = Atom.new.save

      response = @server.get "/relaxdb_spec/#{a._id}"
      
      entry = @server.cache_store.get "/relaxdb_spec/#{a._id}"
      entry.should_not be_nil
      entry.etag.should == "\"#{a._rev}\""
      entry.data.should == response.body
    end
    
    it "should fetch results from the cache" do
      a = Atom.new.save
      entry = @server.cache_store.store "/relaxdb_spec/#{a._id}", "dummy data", "\"#{a._rev}\""
      
      response = @server.get "/relaxdb_spec/#{a._id}"
      response.body.should == "dummy data"
    end
    
    it "should not get stale data from the cache" do
      a = Atom.new.save
      entry = @server.cache_store.store "/relaxdb_spec/#{a._id}", "dummy data", "\"#{a._rev}\""
      a.save
      response = @server.get "/relaxdb_spec/#{a._id}"
      response.body.should_not == "dummy data"
    end
  end
  
end
