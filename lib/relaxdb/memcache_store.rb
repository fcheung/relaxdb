gem 'memcache-client'
require 'memcache'
require 'zlib'
module RelaxDB
  class MemcacheStore
    def initialize(*args_for_memcache)
      @cache = MemCache.new *args_for_memcache
    end
    
    def get_etag(cache_key)
      @cache.get "etag:#{cache_key}"
    end
    
    def get_data(cache_key)
      entry = @cache.get "data:#{cache_key}"
      if entry[:deflated]
        Zlib::Inflate.inflate(entry[:data])
      else
        entry[:data]
      end
    end

    def store(cache_key, data, etag)
      deflated = false
      if data.length >= 1024 * 1024
        data = Zlib::Deflate.deflate(data, 1)
        deflated = true
      end
      
      if data.size < 1024*1024 #memcache cannot store values over 1mb
        @cache.set( "data:#{cache_key}", {:data => data, :deflated => deflated})
        @cache.set( "etag:#{cache_key}", etag)
      end
    end
  end
end