require 'typhoeus'
module RelaxDB
  
  class HTTP_404 < StandardError; end
  class HTTP_409 < StandardError; end
  class HTTP_412 < StandardError; end
  
  class CacheEntry
    attr_accessor :data, :etag
    def initialize(data, etag)
      self.data = data
      self.etag = etag
    end
  end
  
  class NilStore
    def get_etag(cache_key)
    end
    def get_data(cache_key)
    end
    def store(cache_key, data,etag)
    end
    
    def clear
    end
  end
  
  class MemoryStore
    def initialize(options={})
      @cache = {}
      @maximum_entry_size = options[:maximum_entry_size]
      @size = options[:size] || 100
      @cache_order = []
    end
    
    def clear
      @cache = {}
    end
    
    def get(cache_key)
      value = @cache[cache_key]
      push_key_to_top cache_key if value
      value
    end
    
    def get_etag(cache_key)
      entry = get(cache_key)
      entry && entry.etag
    end
    
    def get_data(cache_key)
      entry = get(cache_key)
      entry && entry.data
    end
    
    def store(cache_key, data, etag)
      if @maximum_entry_size.nil? || data.length <= @maximum_entry_size
        if @cache.size >= @size && !@cache.has_key?(cache_key)
          first_key = @cache_order.shift
          @cache.delete first_key
        end
        push_key_to_top cache_key
        @cache[cache_key] = CacheEntry.new(data, etag)
      end
    end
    
    private
    def push_key_to_top key
      @cache_order.delete_if {|k| k == key} if @cache.has_key? key
      @cache_order << key
    end
  end
  
  class Server
    attr_reader :cache_store
    class Response
      attr_reader :status, :body, :etag
      def initialize status, body, etag
        @status, @body, @etag = status, body, etag
      end
    end
    
    def initialize(host, port, cache_store)
      @host, @port = host, port
      @cache_store = cache_store || NilStore.new
    end


    def delete(uri)
      handle_response Typhoeus::Request.delete("http://#{@host}:#{@port}#{uri}")
    end

    def uncached
      old_uncached = @uncached
      @uncached = true
      yield
    ensure
      @uncached = old_uncached
    end
    
    def get(uri)
      etag = !@uncached && cache_store.get_etag( uri)
      if etag
        headers = {:'If-None-Match' => etag}
      else
        headers = {}
      end
      
      response = handle_response Typhoeus::Request.get("http://#{@host}:#{@port}#{uri}", :headers => headers)
    
      if etag && response.status == 304
        data = cache_store.get_data uri
        if data
          return Response.new( 200, data, etag)
        else
          #we don't have the data in our cache anymore boohoo
          response = handle_response Typhoeus::Request.get("http://#{@host}:#{@port}#{uri}")
        end
      end
      
      cache_store.store uri, response.body, response.etag unless @uncached
      response
    end
    
    def put(uri, json)
      handle_response Typhoeus::Request.put("http://#{@host}:#{@port}#{uri}", :body => json, :headers => {:'Content-Type' => 'application/json'})
    end

    def post(uri, json)
      handle_response Typhoeus::Request.post("http://#{@host}:#{@port}#{uri}", :body => json, :headers => {:'Content-Type' => 'application/json'})
    end
    
    def handle_response response
      if response.headers.strip =~ /^etag:\s*(.*)\r$/i
        etag = $1
      else
        etag = nil
      end
      
      if response.code < 200 || response.code >= 300 && response.code != 304
        status_line = response.headers.split('\r\n').first
        handle_error response.code, status_line, response.requested_http_method, response.requested_url, ''
      end
      Response.new response.code, response.body, etag
    end


    def to_s
      "http://#{@host}:#{@port}/"
    end
    
    protected
    
    def handle_error status_code, status_line, method, uri, body
      msg = "#{status_code}:#{status_line}\nMETHOD:#{method}\nURI:#{uri}\n#{body}"
      begin
        klass = RelaxDB.const_get("HTTP_#{status_code}")
        e = klass.new(msg)
      rescue
        e = RuntimeError.new(msg)
      end

      raise e
    end
  end
  
      
  class CouchDB

    attr_reader :logger, :server
        
    # Used for test instrumentation only i.e. to assert that 
    # an expected number of requests have been issued
    attr_accessor :get_count, :put_count, :post_count
        
    def initialize(config)
      @get_count, @post_count, @put_count = 0, 0, 0
      @server = RelaxDB::Server.new(config[:host], config[:port], config[:cache_store])
      @logger = config[:logger] ? config[:logger] : Logger.new(Tempfile.new('relaxdb.log'))
    end
    
    def use_db(name)
      create_db_if_non_existant(name)
      @db = name
    end
    
    def db_exists?(name)
      @server.get("/#{name}") rescue false
    end
    
    # URL encode slashes e.g. RelaxDB.delete_db "foo%2Fbar"
    def delete_db(name)
      # Close the http connection as CouchDB will keep a file handle to the db open
      # if the http connection remains open - this will result in CouchDB throwing
      # emfile errors after a significant number of databases are deleted.
      @server.close_connection
      
      @logger.info("Deleting database #{name}")
      @server.delete("/#{name}")
    end
    
    def list_dbs
      JSON.parse(@server.get("/_all_dbs").body)
    end
    
    def replicate_db(source, target)
      @logger.info("Replicating from #{source} to #{target}")
      create_db_if_non_existant target      
      # Manual JSON encoding to allow for dbs containing a '/'
      data = %Q({"source":"#{source}","target":"#{target}"})       
      @server.post("/_replicate", data)
    end

    def delete(path=nil)
      @logger.info("DELETE /#{@db}/#{unesc(path)}")
      benchmark{ @server.delete("/#{@db}/#{path}")}
    end
    
    def get(path=nil)
      @get_count += 1
      @logger.info("GET /#{@db}/#{unesc(path)}")
      benchmark{ @server.get("/#{@db}/#{path}")}
    end
        
    def post(path=nil, json=nil)
      @post_count += 1
      @logger.info("POST /#{@db}/#{unesc(path)} #{json[0,512]}")
      benchmark{ @server.post("/#{@db}/#{path}", json)}
    end
    
    def put(path=nil, json=nil)
      @put_count += 1
      @logger.info("PUT /#{@db}/#{unesc(path)} #{json[0,512]}")
      benchmark{ @server.put("/#{@db}/#{path}", json)}
    end
    
    def uuids(count=1)
      @get_count += 1
      uri = "/_uuids?count=#{count}"
      @logger.info "GET #{uri}"
      @server.get uri
    end
    
    def unesc(path)
      # path
      path ? ::CGI::unescape(path) : ""
    end
    
    def uri
      "#@server" / @db
    end
    
    def name
      @db
    end
    
    def name=(name)
      @db = name
    end
    
    def req_count
      get_count + put_count + post_count
    end
    
    def reset_req_count
      @get_count = @put_count = @post_count = 0
    end
            
    private
    
    def benchmark
      start = Time.now
      res = yield
      finish = Time.now
      t = ((finish - start)*1000).to_i
      @logger.info "(#{t}ms)"
      res
    end
    
    def create_db_if_non_existant(name)
      begin
        @server.get("/#{name}")
      rescue
        @server.put("/#{name}", "")
      end
    end
    
  end
        
end
