class EmbeddedConversation
  include MongoMapper::EmbeddedDocument
  
  key :title, :required => true
  key :slug, :required => true
  key :post_count, Integer, :default => 0
  key :open, Boolean, :default => true
  key :sticky, Boolean, :default => true
  
  key :last_post, EmbeddedPost
  key :author, EmbeddedProfile, :required => true
  key :original_id, ObjectId, :required => true
  
  def original
    Conversation.find original_id
  end
end
