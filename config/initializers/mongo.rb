if ENV['MONGOHQ_URL'] # For Heroku's MongoHQ addon
  MongoMapper.config = { Rails.env => {'uri' => ENV['MONGOHQ_URL']} }
else
  MongoMapper.config = { Rails.env => {'uri' => "mongodb://localhost:27017/twelvestone-#{Rails.env}"} }
end

MongoMapper.connect Rails.env
