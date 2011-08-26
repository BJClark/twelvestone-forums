class Community
  include MongoMapper::Document
  include MongoMapper::Sluggable

  key :name, String, :required => true
  key :introduction, String, :required => true
  
  many :forums
end
