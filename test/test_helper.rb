ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  #include Devise::TestHelpers
  def setup
    teardown
  end
  def teardown
    MongoMapper.database.collections.each do |collection|
      collection.remove
    end    
  end
end
class << Time
  alias_method(:now_original, :now) unless method_defined?(:now_original)
  
  def now
    @now_offset ? now_original + @now_offset : now_original
  end
  
  def with_flux_capacitor(time_offset, &block)
    @now_offset = time_offset
    yield
  ensure
    reset!
  end
  
  def time_travel(time_offset)
    @now_offset ||= 0
    @now_offset += time_offset
  end
  
  def reset!
    @now_offset = nil
  end
end
