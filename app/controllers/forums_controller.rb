class ForumsController < ApplicationController
  include ApplicationHelper
  # before_filter :authenticate
  
  def index
    @page_title       = current_community.name
    @page_description = current_community.introduction
    @forums           = current_community.forums.in_order.paginate :page => params[:page]
  end
  
  def show
    @forum            = Forum.find_by_slug params[:id]
    @page_title       = "Hey Foxy Forums: #{@forum.name}"
    @page_description = @forum.description
    @sticky           = @forum.conversations.by_date.sticky
    @conversations    = @forum.conversations.by_date.paginate :per_page => 50, :page => params[:page], :sticky => false
  end
end
