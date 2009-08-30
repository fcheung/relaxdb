module RelaxDB

  class HasManyProxy

    include Enumerable
    
    attr_reader :children
  
    def initialize(client, relationship, opts)
      @client = client 
      @relationship = relationship
      @opts = opts

      @target_class = opts[:class] 
      @relationship_as_viewed_by_target = (opts[:known_as] || client.class.name.snake_case).to_s

      @children = []
      @loaded = false
    end


    def <<(obj)
      load_children unless loaded?
      return false if @children.include?(obj)

      obj.send("#{@relationship_as_viewed_by_target}=".to_sym, @client)
      if obj.save
        @children << obj
        self
      else
        false
      end
    end
  
    def clear
      load_children unless loaded?
      @children.each do |c|
        break_back_link c
      end
      @children.clear
    end
  
    def delete(obj)
      load_children unless loaded?
      obj = @children.delete(obj)
      break_back_link(obj) if obj
    end
  
    def break_back_link(obj)
      if obj
        obj.send("#{@relationship_as_viewed_by_target}=".to_sym, nil)
        obj.save
      end
    end
  
    def empty?
      load_children unless loaded?
      @children.empty?
    end
  
    def size
      load_children unless loaded?
      @children.size
    end
  
    def [](*args)
      load_children unless loaded?
      @children[*args]
    end
    
    def first
      load_children unless loaded?
      @children[0]
    end
    
    def last
      load_children unless loaded?
      @children[size-1]
    end
  
    def each(&blk)
      load_children unless loaded?
      @children.each(&blk)
    end
  
    def reload
      @children = load_children
    end
  
    def load_children
      view_name = "#{@client.class}_#{@relationship}"
      if @opts[:order]
        @children = RelaxDB.view(view_name, :startkey => [@client._id], :endkey => [@client._id,{}])
      else
        @children = RelaxDB.view(view_name, :key => @client._id)
      end  
      loaded!
    end
    
    def children=(children)
      load_children unless loaded?
      children.each do |obj|
        obj.send("#{@relationship_as_viewed_by_target}=".to_sym, @client)
      end
      @children = children
    end
  
    def inspect
      load_children unless loaded?
      @children.inspect
    end
    
    def loaded!
      @loaded = true
    end
    
    def loaded?
      @loaded
    end
    # Play nice with Merb partials - [ obj ].flatten invokes
    # obj.to_ary if it responds to to_ary
    alias_method :to_ary, :to_a
  
  end

end
