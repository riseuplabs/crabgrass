class NetworksController < GroupsController
  
  before_filter :check_site_settings

  def initialize(options={})
    super
  end

  def show
    super
    @group_pages = Page.find_by_path(['descending', 'updated_at', 'limit','10'], options_for_groups(@group.group_ids)) if @group
  end

  def new
    @group = Network.new
  end
 
  def create
    @group = Network.new params[:group]
    @group.save!
    if member_group = Group.find_by_id(params[:group_id])
      if current_user.may?(:admin, member_group)
        @group.add_group!(member_group)
      else
        @gruop.add_user!(current_user)
      end
    end
    group_created_success
  rescue Exception => exc
    flash_message_now :exception => exc
    render :template => 'groups/new'
  end
  
  protected

  def context
    if action?(:edit)
      group_settings_context
    elsif action?(:create, :new)
      group_context
    else
      @left_column = render_to_string(:partial => '/groups/navigation/sidebar')
      if !action?(:show)
        add_context params[:action], networks_url(:action => params[:action], :id => @group, :path => params[:path])
      end
    end
  end

  def check_site_settings
    unless current_site.has_networks?
      redirect_to (current_site.network ? '/' : '/me/dashboard')
    end
  end
end

