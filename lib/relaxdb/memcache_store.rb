gem 'dalli'
require 'zlib'
require 'digest/sha1'
module RelaxDB
  class MemcacheStore
    attr_reader :cache
    
    def clear
      @cache.flush_all
    end
    
    def initialize(*args_for_memcache)
      @cache = Dalli::Client.new *args_for_memcache
    end
    
    def get_etag(cache_key)
      key = check_key(cache_key)
      @cache.get "etag:#{cache_key}"
    end
    
    def get_data(cache_key)
      key = check_key(cache_key)
      entry = @cache.get "data:#{cache_key}"
      return nil if !entry
      if entry[:deflated]
        Zlib::Inflate.inflate(entry[:data])
      else
        entry[:data]
      end
    end

    def store(cache_key, data, etag)
      key = check_key(cache_key)
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
    
    def check_key(key)
      if key =~ /\s/ || key_length(key) > 250
        key = "#{Digest::SHA1.hexdigest(key)}-autofixed"
      else
        key
      end
    end
  end
end