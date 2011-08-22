require 'test_helper'

class Community::ForumTest < ActiveSupport::TestCase
  
  should "create a new forum" do
    forum = Community::Forum.new valid_forum_attributes
    assert forum.save
  end
  
  should "not allow a new forum without a title and description" do
    forum = Community::Forum.new
    assert !forum.save
  end
  
  should "increment the total post count when a forum is posted in" do
    forum = Community::Forum.create valid_forum_attributes
    con   = Factory "community/conversation", :forum => forum
    assert_difference "forum.post_count", 1 do
      forum.was_posted_in con
      forum.reload
    end
    assert_not_nil forum.last_conversation
  end
  
  def valid_forum_attributes(options = { })
    { :name        => "Tiny Fuckers", 
      :description => "Just two dwarves, living and loving.", 
      :ordinal     => 0 }.merge(options)
  end
end
