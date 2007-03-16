# super class controller for all page types

class Tool::BaseController < ApplicationController
  layout 'tool'
  in_place_edit_for :page, :title
  append_before_filter :setup_view
  append_after_filter :update_participation
    
  def destroy
    if request.post?
      Page.find(params[:id]).destroy
    end
    redirect_to from_url
  end

  def access
    @sidebar = false
    if request.post?
      if group_id = params[:remove_group]
        @page.remove(Group.find_by_id(group_id))
      elsif user_id = params[:remove_user]
        @page.remove(User.find_by_id(user_id))
      end
      @page.save
    end
    render :template => 'pages/access'
  end
  
  protected

  def update_participation
    if logged_in? and @page and params[:action] == 'show'
      current_user.viewed(@page)
    end
  end

  # initializes default view variables. can be overwritten by subclasses.
  def setup_view
    # default, only show comment posts for the 'show' action
    @show_posts = (params[:action] == 'show')
    @sidebar = true
    true
  end
  
  def fetch_page
    if logged_in?
      # include all participations and users in the page object
      @page = Page.find :first, :conditions => ['pages.id = ?', params[:id]], :include => [:user_participations => :user]
      # grab the current user's participation from memory
      @parti = @page.participation_for_user(current_user) if logged_in?
    else
      @page = Page.find(params[:id])
    end
    @page.discussion = Discussion.new unless @page.discussion
    @post_paging, @posts = paginate(:posts, :per_page => 25, :order => 'posts.created_at',
       :include => :user, :conditions => ['posts.discussion_id = ?', @page.discussion.id])
    @post = Post.new
  end
      
  # this is aweful, and should be refactored soon.
  def breadcrumbs
    return unless params[:id]
    @page ||= Page.find_by_id(params[:id]) # page should already be loaded
    if params[:from]
      if logged_in? and params[:from] == 'people' and params[:from_id] == current_user.to_param
        add_crumb 'me', me_url
      else
        add_crumb params[:from], url_for(:controller => '/'+params[:from])
        if params[:from_id]
          if params[:from] == 'groups'
            group = Group.find_by_id(params[:from_id])
            text = group.name if group
          elsif params[:from] == 'people'
            text = params[:from_id]
          end
          if text
            add_crumb text, url_for(:controller => '/'+params[:from], :id => params[:from_id], :action => 'show')
          end
        end
      end
    elsif @page
      # figure out the first group or first user, and use that for breadcrumb.
      if @page.groups.any?
        add_crumb 'groups', groups_url
        group = @page.groups.first
        add_crumb group.name, groups_url(:action => 'show', :id => group)
      elsif @page.created_by
        add_crumb 'people', people_url
        user = @page.created_by
        add_crumb user.login, people_url(:action => 'show', :id => user)
      end
    end

    add_crumb @page.title, page_url(@page, :action => 'show')
  end
  
end
