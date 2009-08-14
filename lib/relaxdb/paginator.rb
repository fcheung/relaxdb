module RelaxDB  

  class Paginator
    
    attr_reader :paginate_params

    def initialize(paginate_params, page_params)
      @paginate_params = paginate_params
      @orig_paginate_params = @paginate_params.clone
      
      page_params = page_params.is_a?(String) ? JSON.parse(page_params).to_mash : page_params
      # Where the magic happens - the original params are updated with the page specific params
      @paginate_params.update(page_params)
    end

    def total_doc_count(view_name)
      RelaxDB.view view_name, :startkey => @orig_paginate_params.startkey, :endkey => @orig_paginate_params.endkey,
        :descending => @orig_paginate_params.descending, :reduce => true
    end
    
    #
    # view_keys are used to determine the params for the prev and next links. If a view_key is a symbol
    # the key value will be the result of invoking the method named by the symbol on the first / last 
    # element in the result set. If a view_key is not a symbol, its value will be used directly.
    #
    def add_next_and_prev(docs, view_name, view_keys)
      unless docs.empty?
        no_docs = docs.size
        offset = docs.offset
        orig_offset = orig_offset(view_name)
        total_doc_count = total_doc_count(view_name)      
      
        next_exists = !@paginate_params.order_inverted? ? (offset - orig_offset + no_docs < total_doc_count) : true
        next_params = create_next(docs.last, view_keys) if next_exists
    
        prev_exists = @paginate_params.order_inverted? ? (offset - orig_offset + no_docs < total_doc_count) : 
          (offset - orig_offset == 0 ? false : true)
        prev_params = create_prev(docs.first, view_keys) if prev_exists
      else
        next_exists = prev_exists = false
      end
      
      docs.meta_class.instance_eval do        
        define_method(:next_params) { next_exists ? next_params : false }
        define_method(:next_query) { next_exists ? "page_params=#{::CGI::escape(next_params.to_json)}" : false }
        
        define_method(:prev_params) { prev_exists ? prev_params : false }
        define_method(:prev_query) { prev_exists ? "page_params=#{::CGI::escape(prev_params.to_json)}" : false }
      end      
    end
    
    def create_next(doc, view_keys)
      next_key = view_keys_to_vals doc, view_keys
      next_key = next_key.length == 1 ? next_key[0] : next_key
      next_key_docid = doc._id
      { :startkey => next_key, :startkey_docid => next_key_docid, :descending => @orig_paginate_params.descending }
    end
    
    def create_prev(doc, view_keys)
      prev_key = view_keys_to_vals doc, view_keys
      prev_key = prev_key.length == 1 ? prev_key[0] : prev_key
      prev_key_docid = doc._id
      prev_params = { :startkey => prev_key, :startkey_docid => prev_key_docid, :descending => !@orig_paginate_params.descending }
    end
    
    def view_keys_to_vals doc, view_keys
      view_keys.map do |k|
        if k.is_a?(Symbol) then doc.send(k)
        elsif k.is_a?(Proc) then k.call(doc)
        else k
        end
      end
    end
    
    def orig_offset(view_name)
      if @paginate_params.order_inverted?
        params = {:startkey => @orig_paginate_params.endkey, :descending => !@orig_paginate_params.descending}
      else
        params = {:startkey => @orig_paginate_params.startkey, :descending => @orig_paginate_params.descending}
      end
      params[:limit] = 1
            
      RelaxDB.view(view_name, params).offset
    end
    
  end
  
end
