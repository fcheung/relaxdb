class FooBar < RelaxDB::Document
  references :bf
end

class BarFoo < RelaxDB::Document
  references :fb
end

class Atom < RelaxDB::Document
end

class Initiative < RelaxDB::Document
  property :x
  attr_reader :foo
  def initialize(data)
    data[:_id] = data[:x]
    super data
    @foo = :bar
  end
end

class Primitives < RelaxDB::Document

  property :str
  property :num
  property :true_bool
  property :false_bool
  property :created_at
  property :updated_at
  property :context
  
  view_docs_by :num
  
  view_by :str

end

class PrimitivesChild < Primitives
end

class BespokeReader < RelaxDB::Document
  property :val
  def val; @data['val'] + 5; end
end

class BespokeWriter < RelaxDB::Document
  property :val
  property :tt
  def val=(v); @data['val'] = v - 10; end
  def tt=(t); @data['tt'] = t.is_a?(String) ? Time.parse(t) : t; end
end

class Invite < RelaxDB::Document

  property :message

  belongs_to :sender
  belongs_to :recipient
  
end

class Item < RelaxDB::Document

  property :name
  belongs_to :user
  
  view_docs_by :user_id

end

class User < RelaxDB::Document

  property :name, :default => "u" 
  property :age

  has_many :items, :class => "Item"

  has_many :invites_received, :class => "Invite", :known_as => :recipient
  has_many :invites_sent, :class => "Invite", :known_as => :sender
  
  has_many :ordered_items, :class => 'Item', :order => :name
  view_docs_by :name, :age

end

class Post < RelaxDB::Document

  property :subject
  property :content
  property :created_at
  property :viewed_at
  
  view_docs_by :content
  view_docs_by :subject
  view_docs_by :viewed_at

end

class Rating < RelaxDB::Document

  property :stars, :default => 5
  belongs_to :photo
  
  view_docs_by :stars

end

class Photo < RelaxDB::Document

  property :name

  has_one :rating

  references_many :tags, :class => "Tag", :known_as => :photos

  has_many :taggings, :class => "Tagging"

end

class Tag < RelaxDB::Document

  property :name
  references_many :photos, :class => "Photo", :known_as => :tags

  has_many :taggings, :class => "Tagging"

end

class Tagging < RelaxDB::Document

  belongs_to :photo
  belongs_to :tag
  property :relevance  

end

class MultiWordClass < RelaxDB::Document
  has_one :multi_word_child
  has_many :multi_word_children, :class => "MultiWordChild"
end

class MultiWordChild < RelaxDB::Document
  belongs_to :multi_word_class
end

class TwitterUser < RelaxDB::Document

  property :name
  references_many :followers, :class => "User", :known_as => :leaders
  references_many :leaders, :class => "User", :known_as => :followers

end

class Dysfunctional < RelaxDB::Document
  has_one :failure
  has_many :failures, :class => "Failure"
end

class Failure < RelaxDB::Document
  property :pathological, :validator => lambda { false }
  belongs_to :dysfunctional
end

class Letter < RelaxDB::Document
  property :letter
  property :number
  view_docs_by :letter, :number
  view_docs_by :number
end

class Ancestor < RelaxDB::Document

  property :x
  property :y, :default => true,
    :validator => lambda { |y| y },
    :validation_msg => "Uh oh"
    
  references :user
  property :user_name,
    :derived => [:user, lambda { |p, o| o.user.name } ]
    
  view_docs_by :x
end

class Descendant < Ancestor
end

class SubDescendant < Descendant
end

class RichDescendant < Descendant
  property :foo
  
  references :ukulele
  property :ukulele_name,
    :derived => [:ukulele, lambda { |p, o| o.ukulele.name } ]
end

class Contrived < RelaxDB::Document
  
  attr_accessor :context_count
  def initialize params = {}
    @context_count = 0
    super
  end
  
  property :foo,
    :default => 5,
    :derived => [
      :context,
      lambda { |f, c| c.context_count += 1; 10 }
    ]
  
  references :context
end

module Inh
  
  class X < RelaxDB::Document; end

  class Y < X; end
  class Y1 < Y; end
  
  class Z < X; end
  class Z1 < Z; end
  class Z2 < Z; end
  
end
