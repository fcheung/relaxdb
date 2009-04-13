require File.dirname(__FILE__) + '/spec_helper.rb'

describe RelaxDB::MemoryStore do
  
  describe "cache" do
    it "should not store objects bigger than the maximum size" do
      @store = RelaxDB::MemoryStore.new :maximum_entry_size => 30
      @store.store 'some_key', 'x' * 30, 'tag'
    
      @store.get('some_key').should_not be_nil

      @store.store 'some_other_key', 'x' * 31, 'tag'
      @store.get('some_other_key').should be_nil
    end
  
    it "should store and retrieve objects" do
      @store = RelaxDB::MemoryStore.new 
      @store.store 'some_key', 'x' * 30, 'tag'
      entry = @store.get 'some_key'
      entry.data.should == 'x' * 30
      entry.etag.should == 'tag'
    end
  
    it "should remove old items from the cache" do
      @store = RelaxDB::MemoryStore.new :size => 2

      @store.store 'first_key', 'data', 'tag'
      @store.store 'second_key', 'data', 'tag'
      @store.store 'third_key', 'data', 'tag'

      @store.get('second_key').should_not be_nil
      @store.get('third_key').should_not be_nil
      @store.get('first_key').should be_nil
    end
  
    it "should not remove items from cache when storing an existing key" do
      @store = RelaxDB::MemoryStore.new :size => 2
      @store.store 'first_key', 'data', 'tag'
      @store.store 'second_key', 'data', 'tag'
      @store.store 'second_key', 'data2', 'tag'
      @store.store 'second_key', 'data3', 'tag'
    
      @store.get('second_key').should_not be_nil
      @store.get('first_key').should_not be_nil    
    end
  
    it "should push items to the front of the queue" do
      @store = RelaxDB::MemoryStore.new :size => 2
      @store.store 'first_key', 'data', 'tag'
      @store.store 'second_key', 'data', 'tag'
    
      @store.get('first_key')
      @store.store 'third_key', 'data', 'tag'

      @store.get('second_key').should be_nil
      @store.get('third_key').should_not be_nil
      @store.get('first_key').should_not be_nil
    end
  end
end