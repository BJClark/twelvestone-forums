class ConversationsController < ApplicationController
  before_filter :authenticate, :except => [ :show ]
  before_filter :require_admin, :only => [ :update, :edit ]
  before_filter :find_conversation, :only => [ :show, :edit, :update, :unsubscribe ]
  before_filter :check_forum_restriction, :only => [ :show, :create ]
  
  def show
    @page_title       = @conversation.title
    @page_description = @conversation.summary
    @page             = params[:page] == "last" ? @conversation.total_pages_from_post_count : (params[:page] || 1)
    @posts            = @conversation.posts.by_date.paginate :page => @page
    @new_post         = @conversation.posts.build
    @conversation.check_post_counter @posts
    if params[:quote]
      quoted         = Post.find params[:quote]
      @new_post.text = quoted.quoted_text unless quoted.nil?
    end
  end
  
  def new
    @conversation = Conversation.new :forum_id => params[:forum_id]
    @post         = @conversation.posts.build
    if params[:blog_title]
      @conversation.title      = params[:blog_title]
      @conversation.remote_url = params[:remote_url]
      @hide_title              = true
    end
  end
  
  def edit
    render :partial => "community/conversations/edit"
  end
  
  def update
    @conversation.title  = params[:conversation][:title]
    @conversation.open   = params[:conversation][:open]   == "1"
    @conversation.sticky = params[:conversation][:sticky] == "1"
    
    if @conversation.save
      render :partial => "community/conversations/row", :locals => { :row => @conversation }, :status => :ok
    else
      render :json => @conversation.errors.to_json, :status => :unprocessable_entity
    end
  end
  
  def create
    @forum              = Forum.find params[:conversation].delete :forum_id
    @conversation       = @forum.conversations.build params[:conversation]
    @post               = @conversation.posts.build params[:post]
    @post.author        = current_user.as_embedded
    @conversation.forum = @forum
    
    if @conversation.save
      begin
        @post.save!
        redirect_to forum_url(@conversation.forum)
      rescue
        @conversation.destroy
        render :new
      end
    else
      render :new
    end
  end
  
  def unsubscribe
    @conversation.remove_subscriber current_user
    render :json => true
  end
  
  protected
  def find_conversation
    @conversation = Conversation.find_by_slug params[:id]
    if @conversation.nil?
      render :conversation_not_found, :status => :not_found
    end
  end
  
  def require_admin
    render :json => false, :status => :unauthorized unless current_user.admin?
  end
  
  def check_forum_restriction
    forum = @conversation.try(:forum) || Forum.find_by_id(params[:conversation][:forum_id])
    if not forum.allowed?(current_user)
      flash[:error] = "You don't have permission to post in this forum."
      redirect_to forums_path
    end
  end
  
end
