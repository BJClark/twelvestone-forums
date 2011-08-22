class Community::EmbeddedPost
  include MongoMapper::EmbeddedDocument
  
  key :author, EmbeddedProfile, :required => true
  key :deleted, Boolean, :required => true
  key :nsfw, Boolean, :required => true
  key :original_id, ObjectId, :required => true
  key :summary, String
  
  def original_post
    Community::Post.find original_id
  end
  
end
