module RelaxDB

  class BelongsToProxy

    attr_reader :target
  
    def initialize(client, relationship)
      @client = client
      @relationship = relationship
      @target = nil
    end
  
    def target
      return @target if @target
            
      id = @client.instance_variable_get("@#{@relationship}_id")
      @target = RelaxDB.load(id) if id
    end
  
    # Not convinced by the semantics of this method. Revise.
    def target=(new_target)
      id = new_target ? new_target._id : nil
      @client.instance_variable_set("@#{@relationship}_id", id) 
      
      @target = new_target
    end
    
  end

end