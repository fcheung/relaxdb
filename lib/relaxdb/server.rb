module RelaxDB
  
  class HTTP_404 < StandardError; end
  class HTTP_409 < StandardError; end
  class HTTP_412 < StandardError; end
  
  class Server
    class Response
      attr_reader :body
      def initialize body
        @body = body
      end
    end
    
    def initialize(host, port)
      @host, @port = host, port
    end
    
    def delete(uri)
      request(uri, 'delete'){ |c| c.http_delete}
    end

    def get(uri)
      request(uri, 'get'){ |c| c.http_get}
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
      yield c
      
      if c.response_code < 200 || c.response_code >= 300
        status_line = c.header_str.split('\r\n').first
        msg = "#{c.response_code}:#{status_line}\nMETHOD:#{method}\nURI:#{uri}\n#{c.body_str}"
        begin
          klass = RelaxDB.const_get("HTTP_#{c.response_code}")
          e = klass.new(msg)
        rescue
          e = RuntimeError.new(msg)
        end

        raise e
      end
      Response.new c.body_str
    end  

    def to_s
      "http://#{@host}:#{@port}/"
    end

  end
  
      
  class CouchDB

    attr_reader :logger
        
    # Used for test instrumentation only i.e. to assert that 
    # an expected number of requests have been issued
    attr_accessor :get_count, :put_count, :post_count
        
    def initialize(config)
      @get_count, @post_count, @put_count = 0, 0, 0
      @server = RelaxDB::Server.new(config[:host], config[:port])
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
