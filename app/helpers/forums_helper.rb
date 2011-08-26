module ForumsHelper
  MAX_PAGES = 4
  def conversation_pages(conversation)
    links       = [] 
    total_pages = conversation.total_pages_from_post_count
    total_pages > MAX_PAGES ? (pages = MAX_PAGES) : (pages = total_pages)
    pages.times do |n|
      label = n+1 == MAX_PAGES ? "last" : n+1
      page  = n+1 == MAX_PAGES ? total_pages : n+1
      links << link_to(label, conversation_path(conversation, :page => page))
    end
    links.length > 1 ? links : []
  end
  
  def conversation_links(conversation)
    pages = conversation_pages conversation
    if pages.empty?
      ""
    else
      "[ " + conversation_pages(conversation).join(" ") + " ]"
    end
  end    
end
