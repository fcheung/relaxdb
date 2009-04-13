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
  end
  
  class MemoryStore
    def initialize(options={})
      @cache = {}
      @maximum_entry_size = options[:maximum_entry_size]
      @size = options[:size] || 100
      @cache_order = []
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
      request(uri, 'delete'){ |c| c.http_delete}
    end

    def get(uri)
      etag = cache_store.get_etag uri
      
      response = request(uri, 'get') do |c| 
        c.headers['If-None-Match'] = etag
        c.http_get
      end
      
      if etag && response.status == 304
        data = cache_store.get_data uri
        if data
          return Response.new( 200, data, etag)
        else
          #we don't have the data in our cache anymore boohoo
          response = request(uri, 'get') {|c| c.http_get }
        end
      end
      
      cache_store.store uri, response.body, response.etag
      response
    end

    def put(uri, json)
      request(uri, 'put') do |c| 
        c.headers['content-type'] = 'application/json'
        c.http_put json
      end
    end

    def post(uri, json)
      request(uri, 'post') do |c| 
        c.headers['content-type'] = 'application/json'
        c.http_post json
      end
    end

    def request(uri, method)
      c = Curl::Easy.new "http://#{@host}:#{@port}#{uri}"
      etag = status_line = nil

      c.on_header do |header_string|
        if !status_line
          status_line = header_string
        elsif header_string.strip =~ /etag:\s*(.*)/i
          etag = $1
        end
        header_string.length
      end
      
      yield c
      
      if (c.response_code < 200 || c.response_code >= 300) && c.response_code != 304
        handle_error c.response_code, status_line, method, uri, c.body_str
      end
      Response.new c.response_code, c.body_str, etag
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

    attr_reader :logger
        
    # Used for test instrumentation only i.e. to assert that 
    # an expected number of requests have been issued
    attr_accessor :get_count, :put_count, :post_count
        
    def initialize(config)
      @get_count, @post_count, @put_count = 0, 0, 0
      @server = RelaxDB::Server.new(config[:host], config[:port], config[:cache_store])
      @logger = config[:logger] ? config[:logger] : Logger.new(Tempfile.new('couchdb.log'))
    end
    
    def use_db(name)
      create_db_if_non_existant(name)
      @db = name
    end
    
    def db_exists?(name)
      @server.get("/#{name}") rescue false
    end
    
    def delete_db(name)
      @logger.info("Deleting database #{name}")
      @server.delete("/#{name}")
    end
    
    def list_dbs
      JSON.parse(@server.get("/_all_dbs").body)
    end
    
    def replicate_db(source, target)
      @logger.info("Replicating from #{source} to #{target}")
      create_db_if_non_existant target      
      data = { "source" => source, "target" => target}
      @server.post("/_replicate", data.to_json)
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
      @logger.info("POST /#{@db}/#{unesc(path)} #{json}")
      benchmark{ @server.post("/#{@db}/#{path}", json)}
    end
    
    def put(path=nil, json=nil)
      @put_count += 1
      @logger.info("PUT /#{@db}/#{unesc(path)} #{json}")
      benchmark{ @server.put("/#{@db}/#{path}", json)}
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
