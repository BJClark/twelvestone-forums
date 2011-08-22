require 'test_helper'
class Community::ForumsHelperTest < ActionView::TestCase
  include Community::ForumsHelper

  should "correctly paginate the pages of a conversation" do
    conversation            = Factory("community/conversation")
    conversation.post_count = 10
    pages                   = conversation_pages conversation
    assert_equal [], pages
    
    conversation.post_count = 25
    pages                   = conversation_pages conversation
    assert_equal 0, pages.length

    conversation.post_count = 26
    pages                   = conversation_pages conversation
    assert_equal 2, pages.length 
    
    conversation.post_count = 50
    pages                   = conversation_pages conversation
    assert_equal 2, pages.length

    conversation.post_count = 51
    pages                   = conversation_pages conversation 
    assert_equal 3, pages.length
    
    conversation.post_count = 400
    pages                   = conversation_pages conversation
    assert_equal 4, pages.length
    
  end 
    
end
