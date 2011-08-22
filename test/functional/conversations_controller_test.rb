require 'test_helper'

class Community::ConversationsControllerTest < ActionController::TestCase
  def setup
    @conversation            = Factory("community/conversation")
    @profile                 = Factory :profile
    @posts                   = (0..2).collect do |n|
      Time.with_flux_capacitor -n.hours do
        Factory.create("community/post", :conversation => @conversation, :author => @profile.as_embedded) 
      end
    end.reverse
    
    sign_in_as @profile
    @conversation.posts      = @posts
    @conversation.first_post = @posts.first
    @conversation.last_post  = @posts.last
    @conversation.reload
  end
  
  test "a GET request to show should list conversation posts" do
    get :show, :id => @conversation.slug
    assert_equal @conversation, assigns(:conversation)
    assert_equal @posts, assigns(:posts)
    assert_equal @conversation, assigns(:new_post).conversation
  end
  
  test "a GET request to show with the quote variable set should set the post text" do
    get :show, :id => @conversation.slug, :quote => @posts.first.id
    assert_equal @posts.first.quoted_text, assigns(:new_post).text
  end
  
  test "a POST to create adds a new conversation and first post" do
    Time.with_flux_capacitor 1.second do
      assert_difference "Community::Conversation.count", 1 do
        post :create, :community_conversation => { :title    => "I killed a man.", 
                                                   :forum_id => @conversation.forum_id },
                      :community_post         => { :text     => "And I didn't feel a thing." }  
      end
    end
    new_conversation = assigns(:conversation)
    assert_equal new_conversation.posts.first.author.original_id, @profile.id
    assert_redirected_to community_forum_url(@conversation.forum)
    assert_equal new_conversation, new_conversation.forum.conversations.by_date.first
  end
  
  test "a POST to create with invalid params does not create a post or a conversation" do
    assert_no_difference "Community::Conversation.count" do
      assert_no_difference "Community::Post.count" do
        post :create, :community_conversation => { :title    => "I killed a man.", 
                                                   :forum_id => @conversation.forum_id },
                      :community_post         => { :text     => nil }  
      end
    end
    assert !assigns(:post).errors.empty?
  end
  
  test "a PUT request to unsubscribe will remove a subscriber from a converation" do
    subscriber = Profile.find @conversation.subscribers.first
    sign_in_as subscriber
    put :unsubscribe, :id => @conversation.slug
    assert !@conversation.reload.subscribers.include?(subscriber.id)
  end
  
  test "a PUT to update will update the conversation" do
    @conversation.sticky = false
    @conversation.save
    @profile.expects(:admin?).at_least(1).returns(true)
    put :update, :id => @conversation.slug, :community_conversation => { :title => "poop deck", :open => "0" }
    
    assert_response :success
    
    @conversation.reload
    assert_equal "poop deck", @conversation.title
    assert !@conversation.sticky?
    assert !@conversation.open?
  end
  
end
