require 'test_helper'

class Community::PostsControllerTest < ActionController::TestCase
  def setup
    @profile = Factory :profile
    sign_in_as @profile
  end
  
  should "create a post with a signed in user" do
    conversation = Factory "community/conversation"
    assert_difference "Community::Post.count", 1 do
      post :create, :community_post => { :conversation_id => conversation.id, 
                                         :text => "Just two average amputees, living and loving" }
    end
    assert_response :created
  end

  should "respond with errors for invalid post" do
    assert_no_difference "Community::Post.count" do
      post :create, :community_post => { :text => "Shut your whore mouth." }
    end
    
    assert_response :unprocessable_entity
  end
  
  should "show posts since a certain date" do
    conversation = Factory "community/conversation"
    posts        = (0..5).collect do |i|
      Time.with_flux_capacitor -i.days do
        conversation.posts.create :author => @profile, :text => "Fnord 1"
      end
    end
    get :index, :last_post_id => posts[2].id, :conversation_id => conversation.id
    
    expected = Community::Post.since(posts[2].id).collect(&:created_at)
    assert_equal expected, assigns(:posts).collect(&:created_at)
  end
  
  context "a post in the database" do
    setup do
      @conversation = Factory "community/conversation"
      @post         = @conversation.posts.create :author => @profile, :text => "Oi Poopsmith"
    end
  
    should "show a post as json" do
      get :show, :id => @post.id
      json         = JSON.parse(@response.body)
      assert_equal @post.id.to_s, json["id"]
    end
  
    should "redirect to the last page of a conversation and fill the post box" do
      @conversation.post_count = 55
      @conversation.save
      get :quote, :id => @post.id
      assert_redirected_to community_conversation_url(@conversation, :quote => @post.id, :page => 3)
    end
  
    should "return a post as json with the post text set to a quoted value" do
      get :quote, :id => @post.id, :format => "json"
      assert_equal @post.quoted_text, JSON.parse(@response.body)["text"]
    end
    
    should "logically delete a post" do
      delete :destroy, :id => @post.id
    
      assert @post.reload.deleted?
    end
  
    should "return edit form partial if post is editable" do
      get :edit, :id => @post.id
      assert_response :success
      
      @post.author.original_id = BSON::ObjectId.new
      @post.save
      
      get :edit, :id => @post.id
      assert_response :unauthorized
    end
    
    should "update (only) the post text, nsfw, and updated_at time for a post" do
      put :update, :id => @post.id, :community_post => { :text => "Baboon FLESH", :deleted => true }
      @post.reload
      
      assert !@post.deleted?
      assert_equal "Baboon FLESH", @post.text
      assert_in_delta Time.now.utc, @post.updated_at, 5.0
    end
  end
end
