class Post
  include MongoMapper::Document
  include MongoMapper::EmbeddableDocument
  
  timestamps!
  
  key :text, :required => true, :length => 5000
  key :author, User::Embedded, :required => true
  key :deleted, Boolean, :default => false, :protected => true
  key :nsfw, Boolean, :default => false
  key :edited_at, Time, :default => nil
  
  key :conversation_id, ObjectId, :required => true
  belongs_to :conversation, :class => Conversation
  
  after_create :notify_conversation, :increment_post_count
  
  validate :conversation_is_not_closed
  
  scope :by_date, :order => [ [ :created_at, :ascending ] ]
  
  embedded_attributes :author, :deleted, :nsfw, :summary
  
  def self.edit_threshold
    1.day.ago
  end
  
  def self.per_page
    25
  end
  
  def self.since(last_post_id, limit = 20)
    post = Post.find last_post_id
    
    all :conversation_id => post.conversation_id, 
        :created_at.gt   => post.created_at, 
        :order           => [ [ :created_at, :ascending ] ],
        :limit           => limit # safety valve
  end
  
  def quoted_text
    @quoted_text ||= "> _**Originally posted by #{author.name}**_\n>\n" + text.gsub(/^(.*)$/, "> \\1").strip + "\n\n"
  end
  
  def editable?(user)
    !user.nil? && (user.admin? || (created_at > self.class.edit_threshold && user.id == author.original_id))
  end
  
  def summary(options = { })
    options = { :words => 25 }.merge options
    @split   ||= rendered_text.split(/ +/)
    @summary ||= @split[0..(options[:words]-1)]
    
    text = @summary.join(" ").gsub /<\/?[^>]*>/, ""
    text << " . . ." if @summary.length < @split.length
    text
  end
  
  def rendered_text
    @rendered_text ||= RDiscount.new((text || ""), :safelink, :filter_html, :no_pseudo_protocols)
    @rendered_text.to_html
  end
  
  
  protected
  def notify_conversation
    self.conversation.was_posted_in self
  end
  
  def conversation_is_not_closed
    if conversation && !conversation.open?
      errors.add(:conversation, "is closed.")
    end
  end
  
  def increment_post_count
    User.increment author.original_id, :post_count => 1
  end
  
end
