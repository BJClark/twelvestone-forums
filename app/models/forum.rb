class Forum
  include MongoMapper::Document
  include Extensions::Models::Slug
  
  key :name, :required => true, :unique => true

  key :description, :required => true
  key :ordinal, Integer, :required => true, :unique => true
  key :last_conversation, EmbeddedConversation
  key :post_count, Integer, :default => 0
  key :conversation_count, Integer, :default => 0
  key :restricted, String, :default => nil

  many :conversations, :class => Conversation, :foreign_key => :forum_id
  
  scope :in_order, :order => [ :ordinal, :ascending ]
  
  def self.blog_forum
    find_by_slug 'foxy-blog'
  end
  
  def was_posted_in(conversation)
    self.post_count         += 1
    self.last_conversation   = conversation.as_embedded
    save :validate => false
  end
  
  def restricted?
    !restricted.nil?
  end
  
  def allowed?(profile)
    return false if profile.nil? && restricted?
    
    case restricted
    when "premium"
      profile.privilege_level.name == "standard member" || profile.privilege_level.name == "premium member" || profile.admin?
    when "staff"
      profile.admin?
    else
      true
    end
  end
end
