class Conversation
  include MongoMapper::Document
  include MongoMapper::Sluggable
  include MongoMapper::EmbeddableDocument
  
  timestamps!
  
  allow_non_unique_slug
  
  key :title, :required => true, :length => 250
  key :post_count, Integer, :default => 0
  key :open, Boolean,   :default => true
  key :sticky, Boolean, :default => false
  key :last_posted_in, :default => lambda{ Time.now.utc }
  
  key :last_post, Post::Embedded
  key :first_post, Post::Embedded
  
  key :subscribers, Array, :default => []
  key :overflowed, Boolean, :default => false
  
  key :remote_url, :default => nil, :index => true
  
  belongs_to :redirect,     :class => Conversation
  belongs_to :forum,        :class => Forum, :required => true
  many :posts,              :class => Post, :dependent => :destroy, :foreign_key => :conversation_id
  one :subscriber_overflow, :class => SubscriberOverflow, :dependent => :destroy, :foreign_key => :conversation_id
  
  
  scope :by_date, :order => [ [ :last_posted_in, :descending ] ]
  scope :sticky,  :sticky => true
  
  slugged_attr :title
  
  embedded_attributes :title, :slug, :post_count, :open, :sticky, :last_post
  
  
  def self.subscriber_overflow_limit
    50
  end  
  
  def total_pages_from_post_count
    (post_count.to_f / Post.per_page.to_f).ceil
  end
  
  def check_post_counter(paginated_posts)
    if paginated_posts.total_pages != total_pages_from_post_count
      set :post_count => paginated_posts.total_pages
    end
  end
  
  def close!
    self.open = false
    self.save :validate => false
  end
  
  def summary
    first_post.summary
  end
  
  def subscribers
    if overflowed?
      subscriber_overflow.subscribers
    else
      read_key :subscribers
    end
  end
  
  def was_posted_in(post)
    self.post_count    += 1
    self.last_post      = post.as_embedded
    self.last_posted_in = Time.now.utc

    if self.first_post.nil?
      self.first_post = post.as_embedded
    end
    add_subscriber post.author
    notify_subscribers post.author
    forum.was_posted_in self
    save(:validate => false)
  end
  
  def add_subscriber(user)
    subscriber_id = user.respond_to?(:original_id) ? user.original_id : user.id
    if not overflowed?
      subs = read_key :subscribers
      if subs.length >= self.class.subscriber_overflow_limit
        self.subscriber_overflow = SubscriberOverflow.create! :subscribers => subs.push(subscriber_id).uniq, :conversation_id => self.id
        self.overflowed  = true
        subs.clear
      else
        subs << subscriber_id and subs.uniq!
      end
      write_key :subscribers, subs
    else
      add_subscriber_to_overflow subscriber_id
    end
  end
  
  def remove_subscriber(user)
    subscriber_id = user.respond_to?(:original_id) ? user.original_id : user.id
    if overflowed?
      SubscriberOverflow.pull({ :conversation_id => id }, :subscribers => subscriber_id)
    else
      pull :subscribers => subscriber_id
    end
  end
  
  protected
  
  def add_subscriber_to_overflow(subscriber_id)
    SubscriberOverflow.add_to_set({ :conversation_id => id }, :subscribers => subscriber_id )
  end
  
  def notify_subscribers(author)
    
    # Notification.conversation_reply(self, author, subscribers)
  end
end

