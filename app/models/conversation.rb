class Conversation
  include MongoMapper::Document
  include Extensions::Models::Slug
  timestamps!
  
  allow_non_unique_slug
  
  key :title, :required => true, :length => 250
  key :post_count, Integer, :default => 0
  key :open, Boolean,   :default => true
  key :sticky, Boolean, :default => false
  key :last_posted_in, :default => lambda{ Time.now.utc }
  
  key :last_post, EmbeddedPost
  key :first_post, EmbeddedPost
  
  key :subscribers, Array, :default => []
  key :overflowed, Boolean, :default => false
  
  key :remote_url, :default => nil, :index => true
  
  belongs_to :redirect,     :class => Conversation
  belongs_to :forum,        :class => Forum, :required => true
  many :posts,              :class => Post, :dependent => :destroy, :foreign_key => :conversation_id
  one :subscriber_overflow, :class => SubscriberOverflow, :dependent => :destroy, :foreign_key => :conversation_id
  
  
  scope :by_date, :order => [ [ :last_posted_in, :descending ] ]
  scope :sticky,  :sticky => true
  
  # for compatibility with the slug extension
  alias_method :name, :title
  
  def self.subscriber_overflow_limit
      50
  end
  
  def as_embedded
    EmbeddedConversation.new :title       => title,
                                        :slug        => slug,
                                        :post_count  => post_count,
                                        :open        => open,
                                        :sticky      => sticky,
                                        :last_post   => last_post, 
                                        :original_id => id
   
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
    if not overflowed?
      @subscribers
    else
      subscriber_overflow.subscribers
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
  
  def add_subscriber(profile)
    subscriber_id = profile.respond_to?(:original_id) ? profile.original_id : profile.id
    if not overflowed?
      if subscribers.length >= self.class.subscriber_overflow_limit
        subscriber_overflow.create! :subscribers => @subscribers.push(subscriber_id).uniq
        self.overflowed  = true
        @subscribers.clear
      else
        @subscribers << subscriber_id and @subscribers.uniq!
      end
    else
      add_subscriber_to_overflow subscriber_id
    end
  end
  
  def remove_subscriber(profile)
    subscriber_id = profile.respond_to?(:original_id) ? profile.original_id : profile.id
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
    Notification.conversation_reply(self, author, subscribers)
  end
end

