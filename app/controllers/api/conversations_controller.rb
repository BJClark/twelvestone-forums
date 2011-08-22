module Community
  module Api
    class ConversationsController < ApplicationController
      before_filter :set_forum
      def show
        @conversation = ::Community::Conversation.find_by_remote_url params[:remote_url]
        if @conversation.nil?
          render :json => { :not_found => true, :url => new_community_conversation_url(:forum_id => @forum.id) }, :callback => params[:callback]
        else
          render :json => {:conversation =>  @conversation, 
                           :url => community_conversation_url(@conversation) }, 
                 :callback => params[:callback]
        end
      end
      
      protected
      def set_forum
        @forum = ::Community::Forum.blog_forum
      end
    end
  end
end

