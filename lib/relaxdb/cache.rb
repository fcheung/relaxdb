module RelaxDB
  class << self
  
    def with_cache
      @context_cache ||= {}
      @context_cache[Thread.current.object_id] = {}
      yield
    ensure
      @context_cache.delete Thread.current.object_id
    end
    
    def cache
      @context_cache && @context_cache[Thread.current.object_id]
    end
      
    def cached(_id)
      c = cache
      result = c && cache[_id]
      if result
        RAILS_DEFAULT_LOGGER.info "cache hit for #{_id}"
      end
      result
    end
    
    def store_in_cache(doc)
      c = cache
      if c
        c[doc._id] = doc
      end
    end
    
    def remove_from_cache(doc)
      c = cache
      if c
        c.delete doc._id
      end
    end
  end
end