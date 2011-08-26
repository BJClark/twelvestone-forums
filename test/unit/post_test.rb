require 'test_helper'

class PostTest < ActiveSupport::TestCase
  should "create a new post" do
    post = FactoryGirl.build :post

    assert_difference "post.author.original_document.post_count", 1 do
      post.save
    end
    assert post.valid?
    
    post.text = "blah" * 5000
    assert !post.valid?
  end
  
  should "not create a new post with invalid attributes" do
    post = Post.new
    assert !post.valid?
    post.text   = "poopsmith"
    post.author = FactoryGirl.create :user
    assert !post.valid?, "post should not be valid without a conversation"
    assert !post.save
  end
  
  should "not create a new post if the parent conversation is closed" do
    conversation      = FactoryGirl.create :conversation
    conversation.open = false
    conversation.save!
    
    author       = FactoryGirl.create :user
    post         = Post.create(:text         => "I am hiding in your cupboard",
                               :author       => author.as_embedded,
                               :conversation => conversation)

    assert !post.valid?
    assert !post.errors[:conversation].empty?
  end
  
  
  should "increment post count in parent conversation when created" do
    conversation = FactoryGirl.create :conversation
    author       = FactoryGirl.create :user

    assert_difference "conversation.post_count", 1 do
      post = Post.create(:text         => "I ate a live fish.", 
                         :author       => author.as_embedded,
                         :conversation => conversation)
      
      conversation.reload
    end
  end
  
  should "render markdown text and sanitize it" do
    post = Post.new
    post.text = "_hey hey_ <p>"
    assert_match /<em>hey hey<\/em>/, post.rendered_text.strip
    assert_match /&lt;p/, post.rendered_text
  end
  
  should "find posts created after another post" do
    author       = FactoryGirl.create :user 
    conversation = FactoryGirl.create :conversation
    posts        = (0..5).collect do |i|
      Time.with_flux_capacitor -i.days do
        conversation.posts.create! :author => author.as_embedded, :text => "Fnord 1"
      end
    end.reverse
    since = Post.since posts[2].id
    assert_equal posts[3..5].collect(&:created_at), since.collect(&:created_at)
  end
  
  should "return text with markdown quoted markdown formatting" do
    author = FactoryGirl.create :user
    post   = Post.new :author => author.as_embedded, :text => <<EOS
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
    author       = FactoryGirl.create :user
    conversation = FactoryGirl.create :conversation
    post1        = FactoryGirl.create :post, :conversation => conversation, :author => author.as_embedded

    assert post1.editable?(author)
    
    post2 = nil
    Time.with_flux_capacitor -1.1.day do
      post2 = FactoryGirl.create :post, :conversation => conversation, :author => author.as_embedded
    end

    assert !post2.editable?(author)
    
    # can only edit your own posts
    post3 = FactoryGirl.create :post, :conversation => conversation
    assert !post3.editable?(author)

    # can edit no matter what if you're an admin
    author.expects(:admin?).at_least(3).returns(true)
    
    assert post1.editable?(author)
    assert post2.editable?(author)
    assert post3.editable?(author)
    
  end
  
  should "get the summary of a post" do
    post = Post.new :text => "This is a bunch of post text"
    assert_equal "This is a . . .", post.summary(:words => 3)
    post.text = "This <b>is a bunch</b> of post text."
    assert_equal "This is a . . .", post.summary(:words => 3)

  end
  
end
