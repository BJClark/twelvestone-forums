class SubscriberOverflow
  include MongoMapper::Document
  
  key :conversation_id, ObjectId, :index => true, :required => true, :unique => true
  key :subscribers, Array
end


