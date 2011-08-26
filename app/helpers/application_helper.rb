module ApplicationHelper
  def current_community
    @community ||= Community.first
  end
end
