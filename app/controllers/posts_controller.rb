class PostsController < ApplicationController
  before_filter :authenticate
  before_filter :find_post,        :only => [ :show, :edit, :update, :destroy, :undelete, :quote ]
  before_filter :must_be_editable, :only => [ :edit, :update, :destroy, :undelete ]
  before_filter :check_forum_restriction, :only => [ :create ]
  
  def create
    post              = Post.new params[:post]
    post.author       = current_user.as_embedded
    if post.save
      render :json => true, :status => :created
    else
      render :json => post.errors.to_json, :status => :unprocessable_entity
    end
  end
  
  def index
    @posts = Post.since params[:last_post_id]
    render :partial => "community/posts/post", :collection => @posts
  end
  
  def show
    render :json => @post.to_json
  end
  
  def edit
    render :partial => "community/posts/edit"
  end
  
  def update
    @post.text       = params[:post][:text]
    @post.nsfw       = params[:post][:nsfw]
    @post.edited_at  = Time.now.utc unless current_user.admin?
    
    if @post.save
      render :json => { :nsfw => @post.nsfw, :text => @post.rendered_text }.to_json
    else
      render :json => @post.errors.to_json, :status => :unprocessable_entity
    end
  end
  
  def destroy
    @post.deleted = true
    @post.save :validate => false
    render :json => { :nsfw => @post.nsfw, :text => @post.rendered_text }.to_json, :status => :ok
  end
  
  def undelete
    @post.deleted = false
    @post.save :validate => false
    render :json => { :nsfw => @post.nsfw, :text => @post.rendered_text }.to_json, :status => :ok
  end
  
  def quote
    if @post.deleted?
      respond_to do |format|
        format.html do
          flash[:error] = "The post you were trying to quote was deleted."
          redirect_to conversation_url(@post.conversation) and return
          
        end
        format.json { render :json => false, :status => :unprocessable_entity and return }
      end
    end
    
    page  = (@post.conversation.post_count.to_f / Post.per_page.to_f).ceil
    page  = page == 0 ? 1 : page
    respond_to do |format|
      format.html { 
        redirect_to conversation_url(@post.conversation, :quote => @post.id, :page => page) 
      }
      format.json { render :json => Post.new(:text => @post.quoted_text).to_json }
    end
  end
  
  protected
  def find_post
    @post = Post.find params[:id]
    if @post.nil?
      render :partial => "posts/not_found", :status => :not_found
    end
  end
  
  def must_be_editable
    if not @post.editable? current_user
      render :json => false, :status => :unauthorized
    end
  end
  
  def check_forum_restriction
    @conversation = Conversation.find params[:post][:conversation_id]
    return if @conversation.nil? # this will be caught elsewhere
    
    if !@conversation.forum.allowed? current_user
      flash[:error] = "You are not allowed to post in this conversation"
      redirect_to forums_path
    end
  end
  
end
