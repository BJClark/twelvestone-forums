require 'test_helper'

class ConversationTest < ActiveSupport::TestCase
  context "an existing conversation" do
    setup do
      @forum        = Factory "forum"
      @user         = Factory :user
      @conversation = @forum.conversations.create :title => "Fnord"
    end
    
    should "create a new conversation" do 
      assert @conversation.valid?
    end
    
    should "increment slug" do
      duplicate = Factory.build "conversation", :title => @conversation.title
      assert duplicate.save, duplicate.errors.full_messages.join("\n")
      assert_equal "#{@conversation.slug}-1", duplicate.slug
    end
  end
  
  should "be invalid without valid attributes, duh" do
    conversation = Conversation.new
    assert !conversation.valid?
  end
   
  
  should "increment post_count on #was_posted_in" do
    conversation = Factory.create :conversation
    assert_difference "conversation.post_count", 1 do
      assert_difference "conversation.forum.post_count", 1 do
        Factory.create "post", :conversation => conversation
        conversation.reload
      end
    end
    
    assert_in_delta Time.now.utc.to_f, conversation.last_posted_in.to_f, 1.0
  end
  
  should "update subscribers on was_posted_in" do
    conversation = Factory "conversation"
    assert_difference "conversation.subscribers.length" do
      Factory.create "post", :conversation => conversation
      conversation.reload
    end
  end
  
  context "overflowing subscribers" do
    
    setup do
      Conversation.stubs(:subscriber_overflow_limit).returns(2)
      @conversation = FactoryGirl.create :conversation

      @p1 = Factory.create "post", :conversation => @conversation
      @p2 = Factory.create "post", :conversation => @conversation
      @p3 = Factory.create "post", :conversation => @conversation
      
      @conversation.reload
      @subscriber_ids = [@p1,@p2,@p3].collect { |p| p.author.original_id }
    end
    
    should "overflow subscribers if subscribers grow above subscriber_overflow_limit" do
      assert @conversation.reload.overflowed?
      assert_not_nil @conversation.subscriber_overflow
      assert_equal @subscriber_ids, @conversation.subscribers
    end
      
    should "remove a subscriber" do
      @conversation.remove_subscriber @p1.author
      @conversation.reload
      assert_equal @subscriber_ids - [ @p1.author.original_id ], @conversation.subscribers
    end
  
    # should "notify subscribers when there has been a new post in the conversation" do
      
    #   assert_difference "Notification.count", 3 do
    #     assert_difference "ActionMailer::Base.deliveries.length", 1 do
    #       Factory.create "post", :conversation => @conversation 
    #     end
    #   end

    #   assert_not_nil ActionMailer::Base.deliveries.last.header_string("X-SMTPAPI")
    # end
    
  end
end
