require 'test_helper'

class Community::ForumsControllerTest < ActionController::TestCase
  context "a GET request to index" do
     
    setup do
      @forum1  = Factory "community/forum"        
      @forum2  = Factory "community/forum"
      @profile = Factory :profile
      sign_in_as @profile
      get :index
    end
    
    should "populate a list of forums" do
      forums = assigns :forums
      assert_equal 2, forums.length
      assert_equal @forum1.id, forums.first.id
      assert_equal @forum2.id, forums.second.id
      assert_response :success
    end
  end
  
  context "a GET request to show" do
    setup do
      @forum   = Factory "community/forum"
      @profile = Factory :profile
      sign_in_as @profile
    end
    
    should "find the forum based on the passed slug" do
      2.times do |n|
        Time.with_flux_capacitor -n.days do
          @forum.conversations << Factory("community/conversation", 
                                          :first_post => Factory.build("community/post").as_embedded,
                                          :last_post => Factory.build("community/post").as_embedded)
        end
      end
      get :show, :id => @forum.slug
      assert_equal @forum, assigns(:forum)
      assert_equal @forum.conversations.by_date.all, assigns(:conversations)
    end
  end
    
end
