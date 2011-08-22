class ForumsController < ApplicationController
  # before_filter :authenticate
  
  def index
    @page_title       = "Hey Foxy Forums"
    @page_description = "The community area of Hey Foxy, for asking questions, giving answers, getting help, and socializing."
    @forums           = Forum.in_order.paginate :page => params[:page]
  end
  
  def show
    @forum            = Forum.find_by_slug params[:id]
    @page_title       = "Hey Foxy Forums: #{@forum.name}"
    @page_description = @forum.description
    @sticky           = @forum.conversations.by_date.sticky
    @conversations    = @forum.conversations.by_date.paginate :per_page => 50, :page => params[:page], :sticky => false
  end
end
