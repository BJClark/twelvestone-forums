require 'test_helper'

class Community::PostTest < ActiveSupport::TestCase
  should "create a new post" do
    conversation = Factory "community/conversation"
    author       = Factory :profile
    post         = nil
    assert_difference "author.reload.post_count", 1 do
      post         = Community::Post.create :text         => "I am hiding in your cupboard",
                                            :author       => author.as_embedded,
                                            :conversation => conversation
    end
    assert post.valid?
    
    post.text = "blah" * 5000
    assert !post.valid?
  end
  
  should "not create a new post with invalid attributes" do
    post = Community::Post.new
    assert !post.valid?
    post.text   = "poopsmith"
    post.author = Factory :profile
    assert !post.valid?, "post should not be valid without a conversation"
    assert !post.save
  end
  
  should "not create a new post if the parent conversation is closed" do
    conversation      = Factory "community/conversation"
    conversation.open = false
    conversation.save
    author       = Factory :profile
    post         = Community::Post.create :text         => "I am hiding in your cupboard",
                                          :author       => author.as_embedded,
                                          :conversation => conversation
    assert !post.valid?
    assert post.errors.on(:conversation)
  end
  
  should "return an embedded post with the original id set" do
    conversation = Factory "community/conversation"
    author       = Factory :profile
    post         = Community::Post.create :text         => "I am hiding in your cupboard",
                                          :author       => author.as_embedded,
                                          :conversation => conversation
    embedded     = post.as_embedded
    assert_equal post.id, embedded.original_id
    assert_equal post, embedded.original_post
  end
  
  should "increment post count in parent conversation when created" do
    conversation = Factory "community/conversation"
    author       = Factory :profile
    assert_difference "conversation.post_count", 1 do
      post         = Community::Post.create :text         => "I ate a live fish.", 
                                            :author       => author.as_embedded,
                                            :conversation => conversation
      
      conversation.reload
    end
  end
  
  should "render markdown text and sanitize it" do
    post = Community::Post.new
    post.text = "_hey hey_ <p>"
    assert_match /<em>hey hey<\/em>/, post.rendered_text.strip
    assert_match /&lt;p/, post.rendered_text
  end
  
  should "find posts created after another post" do
    author       = Factory :profile 
    conversation = Factory "community/conversation"
    posts        = (0..5).collect do |i|
      Time.with_flux_capacitor -i.days do
        conversation.posts.create! :author => author, :text => "Fnord 1"
      end
    end.reverse
    since = Community::Post.since posts[2].id
    assert_equal posts[3..5].collect(&:created_at), since.collect(&:created_at)
  end
  
  should "return text with markdown quoted markdown formatting" do
    author = Factory :profile
    post = Community::Post.new :author => author, :text => <<EOS
I am sitting in your cupboard

Watching you drink your tea, totally unawares.
EOS
    expected = <<EXPECTED
> _**Originally posted by #{post.author.name}**_
>
> I am sitting in your cupboard
> 
> Watching you drink your tea, totally unawares.

EXPECTED
    assert_equal expected, post.quoted_text
  end
  
  should "allow editing only if less than edit threshold in age and the user owns the post" do
    author       = Factory :profile
    conversation = Factory "community/conversation"
    post1        = Factory "community/post", :conversation => conversation, :author => author
    
    assert post1.editable?(author)
    
    post2 = nil
    Time.with_flux_capacitor -1.1.day do
      post2 = Factory "community/post", :conversation => conversation, :author => author
    end
    assert !post2.editable?(author)
    
    # can only edit your own posts
    post3 = Factory "community/post", :conversation => conversation
    assert !post3.editable?(author)
    
    # can edit no matter what if you're an admin
    author.expects(:admin?).at_least(3).returns(true)
    
    assert post1.editable?(author)
    assert post2.editable?(author)
    assert post3.editable?(author)
  end
  
  should "get the summary of a post" do
    post = Community::Post.new :text => "This is a bunch of post text"
    assert_equal "This is a . . .", post.summary(:words => 3)
    post.text = "This <b>is a bunch</b> of post text."
    assert_equal "This is a . . .", post.summary(:words => 3)
    
  end
  
end
