class Forum
  include MongoMapper::Document
  include MongoMapper::Sluggable
  
  key :name, :required => true, :unique => true
  
  key :description, :required => true
  key :ordinal, Integer, :required => true, :unique => true
  key :last_conversation, Conversation.embedded_class
  key :post_count, Integer, :default => 0
  key :conversation_count, Integer, :default => 0
  key :restricted, String, :default => nil

  many :conversations, :class => Conversation, :foreign_key => :forum_id
  belongs_to :community

  scope :in_order, :order => [ :ordinal, :ascending ]
  
  slugged_attr :name
  
  def was_posted_in(conversation)
    self.post_count         += 1
    self.last_conversation   = conversation.as_embedded
    save :validate => false
  end
  
  def restricted?
    !restricted.nil?
  end
  
  def allowed?(user)
    return false if user.nil? && restricted?
    
    case restricted
    when "premium"
      user.premium?
    when "staff"
      user.admin?
    else
      true
    end
  end
end
