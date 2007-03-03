# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  include PageUrlHelper
  include Formy
#  Formy::define_formy_keywords
  
  include LinkHelper
    
  # display flash messages with appropriate styling
  def display_messages()
    return "" unless flash[:notice] || flash[:error] || flash[:update]
    if flash[:update]
      type = "update"
      message = flash[:update]
    elsif flash[:notice]
      type = "info"
      message = flash[:notice]
    elsif flash[:error]
      type = "error"
      message = flash[:error]
    end
    img = image_tag("48/#{type}.png")
    header = content_tag("h2", message)
    content_tag("div", img + header + flash[:text].to_s, "class" => "notice #{type}")
  end
    
  def page_icon(pagetype,size=16)
    img = case pagetype
      when 'poll'; 'check'
      else; 'bubble'
    end
    image_tag "#{size}/#{img}.png", :size => "#{size}x#{size}"
  end
 
 #this function needs to go far far away
  #def link_to_page(text, page)
  #  controller = case page.tool_type
  #    when "Poll::Poll"; 'polls'
  #    when "Decider::Text"; 'texts'
  #    when "Text::Text"; 'texts'
  #    else; 'pages'
  #  end
  #  link_to( (text||'&nbsp;'), :controller => 'pages', :action => 'show', :id => page)
  #end 
    
  def link_to_user(user)
    link_to user.login, :controller => 'people', :action => 'show', :id => user
  end

 def link_to_group(group)
    link_to group.name, :controller => 'groups', :action => 'show', :id => group
  end
  #def user_path(user)
  #  url_for :controller => 'person', :action => 'show', :id => user
  #end
    
  def avatar_for(viewable, size='medium')   
    #image_tag avatar_url(:viewable_type => viewable.class.to_s.downcase, :viewable_id => viewable.id, :size => size), :alt => 'avatar', :size => Avatar.pixels(size), :class => 'avatar'
    image_tag avatar_url(:id => (viewable.avatar||0), :size => size), :alt => 'avatar', :size => Avatar.pixels(size), :class => 'avatar'
  end
  
  def ajax_spinner_for(id, spinner="spinner.gif")
    "<img src='/images/#{spinner}' style='display:none; vertical-align:middle;' id='#{id.to_s}_spinner'> "
  end
  
  def link_to_breadcrumbs
    if @breadcrumbs and @breadcrumbs.length > 1
      @breadcrumbs.collect{|b| link_to b[0],b[1]}.join ' &raquo; ' 
    end
  end
  
  def first_breadcrumb
    @breadcrumbs.first.first if @breadcrumbs.any?
  end
  
  
end
