class SubscriberOverflow
  include MongoMapper::Document
  
  key :conversation_id, ObjectId, :index => true
  key :subscribers, Array
end


