=begin
  create_table "groups", :force => true do |t|
    t.string   "name"
    t.string   "full_name"
    t.string   "summary"
    t.string   "url"
    t.string   "type"
    t.integer  "parent_id"
    t.integer  "admin_group_id"
    t.boolean  "council"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "avatar_id"
    t.string   "style"
  end

  associations:
  group.children   => groups
  group.parent     => group
  group.admin_group  => nil or group
  group.users      => users
=end

class Group < ActiveRecord::Base
  attr_accessible :name, :full_name, :short_name, :summary, :language
  
  ####################################################################
  ## about this group

  include CrabgrassDispatcher::Validations
  validates_handle :name
  before_validation :clean_names

  def clean_names
    t_name = read_attribute(:name)
    if t_name
      write_attribute(:name, t_name.downcase)
    end
    
    t_name = read_attribute(:full_name)
    if t_name
      write_attribute(:full_name, t_name.gsub(/[&<>]/,''))
    end
  end

  # the code shouldn't call find_by_name directly, because the group name
  # might contain a space in it, which we store in the database as a plus.
  def self.get_by_name(name)
    return nil unless name
    Group.find_by_name(name.gsub(' ','+'))
  end

  belongs_to :avatar
  has_many :profiles, :as => 'entity', :dependent => :destroy, :extend => ProfileMethods
  
  # TODO: this is really really horrible.
  has_many :tags,
    :finder_sql => %q[
      SELECT DISTINCT tags.* FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id
      WHERE taggings.taggable_type = 'Page' AND taggings.taggable_id IN
        (SELECT pages.id FROM pages INNER JOIN group_participations ON pages.id = group_participations.page_id
        WHERE group_participations.group_id = #{id})],
    :counter_sql => %q[
      SELECT COUNT(DISTINCT tags.id) FROM tags INNER JOIN taggings ON tags.id = taggings.tag_id
      WHERE taggings.taggable_type = 'Page' AND taggings.taggable_id IN
        (SELECT pages.id FROM pages INNER JOIN group_participations ON
         pages.id = group_participations.page_id WHERE group_participations.group_id = #{id})]
  
  # name stuff
  def to_param; name; end
  def display_name; full_name.any? ? full_name : name; end
  def short_name; name; end
  def cut_name; name[0..20]; end

  # visual identity
  def banner_style
    @style ||= Style.new(:color => "#eef", :background_color => "#1B5790")
  end
   
  def committee?; instance_of? Committee; end
  def network?; instance_of? Network; end
  def normal?; instance_of? Group; end  
  

  ####################################################################
  ## relationships to users

  has_one :admin_group, :class_name => 'Group', :foreign_key => 'admin_group_id'   

  has_many :memberships, :dependent => :destroy,
    :before_add => :check_duplicate_memberships,
    :after_add => :update_membership,
    :after_remove => :update_membership

  has_many :users, :through => :memberships do
    def <<(*dummy)
      raise Exception.new("don't call << on group.users");
    end
    def delete(*records)
      super(*records)
      records.each do |user|
        user.clear_peer_cache_of_my_peers
        user.update_membership_cache
      end
      proxy_owner.increment!(:version)
    end
  end
  
  def user_ids
    @user_ids ||= memberships.collect{|m|m.user_id}
  end

  # association callback
  def check_duplicate_memberships(membership)
    membership.user.check_duplicate_memberships(membership)
  end

  # association callback
  def update_membership(membership)
    @user_ids = nil
    self.increment!(:version)
    membership.user.update_membership_cache
    membership.user.clear_peer_cache_of_my_peers
  end

  def relationship_to(user)
    relationships_to(user).first
  end
  def relationships_to(user)
    return [:stranger] unless user
    (@relationships ||= {})[user.login] ||= get_relationships_to(user)
  end
  def get_relationships_to(user)
    ret = []
#   ret << :admin    if ...
    ret << :member   if user.member_of?(self)
#   ret << :peer     if ...
    ret << :stranger if ret.empty?
    ret
  end
  
# maps a user <-> group relationship to user <-> language
#  def in_user_terms(relationship)
#    case relationship
#      when :member;   'friend'
#      when :ally;     'peer'
#      else; relationship.to_s
#    end  
#  end
  
  def may_be_pestered_by?(user)
    begin
      may_be_pestered_by!(user)
    rescue PermissionDenied
      false
    end
  end
  
  def may_be_pestered_by!(user)
    if user.member_of?(self) or publicly_visible_group or (parent and parent.publicly_visible_committees and parent.may_be_pestered_by?(user))
      return true
    else
      raise PermissionDenied.new('You not allowed to share with %s'[:pester_denied] % self.name)
    end
  end

  
  ####################################################################
  ## relationship to pages
  
  has_many :participations, :class_name => 'GroupParticipation', :dependent => :delete_all
  has_many :pages, :through => :participations do
    def pending
      find(:all, :conditions => ['resolved = ?',false], :order => 'happens_at' )
    end
  end

  def add_page(page, attributes)
    participation = page.participation_for_group(self)
    if participation
      participation.update_attributes(attributes)
    else
      page.group_participations.create attributes.merge(:page_id => page.id, :group_id => id)
    end
    page.group_id_will_change!
  end

  def remove_page(page)
    page.groups.delete(self)
    page.group_id_will_change!
  end
  
  def may?(perm, page)
    begin
       may!(perm,page)
    rescue PermissionDenied
       false
    end
  end
  
  # perm one of :view, :edit, :admin
  # this is still a basic stub. see User.may!
  def may!(perm, page)
    gparts = page.participation_for_groups(group_and_committee_ids)
    return true if gparts.any?
    raise PermissionDenied
  end

  ####################################################################
  ## relationship to other groups

#  has_many :federations
#  has_many :networks, :through => :federations

  # Committees are children! They must respect their parent group. 
  # This uses better_acts_as_tree, which allows callbacks.
  acts_as_tree(
    :order => 'name',
    :after_add => :org_structure_changed,
    :after_remove => :org_structure_changed
  )
  alias :committees :children
    
  # returns an array of all children ids and self id (but not parents).
  # this is used to determine if a group has access to a page.
  def group_and_committee_ids
    @group_ids ||= ([self.id] + Group.committee_ids(self.id))
  end
  
  # returns an array of committee ids given an array of group ids.
  def self.committee_ids(ids)
    ids = [ids] unless ids.instance_of? Array
    return [] unless ids.any?
    ids = ids.join(',')
    Group.connection.select_values("SELECT groups.id FROM groups WHERE parent_id IN (#{ids})").collect{|id|id.to_i}
  end
  
  # returns an array of committees visible to appropriate access level
  def committees_for(access)
    if access == :private
      return self.committees
    elsif access == :public
      if profiles.public.may_see_committees?
        return @comittees_for_public ||= self.committees.select {|c| c.profiles.public.may_see?}
      else
        return []
      end
    end
  end
    
  # returns a list of group ids for the page namespace
  # (of the group_ids passed in).
  # wtf does this mean? for each group id, we get the ids
  # of all its relatives (parents, children, siblings).
  def self.namespace_ids(ids)
    ids = [ids] unless ids.instance_of? Array
    return [] unless ids.any?
    ids = ids.join(',')
    parent_ids = Group.connection.select_values("SELECT groups.parent_id FROM groups WHERE groups.id IN (#{ids})").collect{|id|id.to_i}
    return ([ids] + committee_ids(ids) + parent_ids + committee_ids(parent_ids)).flatten.uniq
  end

  # whenever the structure of this group has changed 
  # (ie a committee or network has been added or removed)
  # this function is run. 
  def org_structure_changed(child)
    users.each do |u|
      u.update_membership_cache
    end
    increment!(:version)
  end

  
#  has_and_belongs_to_many :locations,
#    :class_name => 'Category'
#  has_and_belongs_to_many :categories
  
  ######################################################
  ## temp stuff for profile transition
  ## should be removed eventually
    
  def publicly_visible_group
    profiles.public.may_see?
  end
  def publicly_visible_group=(val)
    profiles.public.update_attribute :may_see, val
  end

  def publicly_visible_committees
    profiles.public.may_see_committees?
  end
  def publicly_visible_committees=(val)
    profiles.public.update_attribute :may_see_committees, val
  end

  def publicly_visible_members
    profiles.public.may_see_members?
  end
  def publicly_visible_members=(val)
    profiles.public.update_attribute :may_see_members, val
  end

  def accept_new_membership_requests
    profiles.public.may_request_membership?
  end
  def accept_new_membership_requests=(val)
    profiles.public.update_attribute :may_request_membership, val
  end


  protected
  
  after_save :update_name
  def update_name
    if name_changed?
      update_group_name_of_pages  # update cached group name in pages
      Wiki.clear_all_html(self)   # in case there were links using the old name
      # update all committees (this will also trigger the after_save of committees)
      committees.each {|c| c.parent_name_changed }
    end
  end
   
  def update_group_name_of_pages
    Page.connection.execute "UPDATE pages SET `group_name` = '#{self.name}' WHERE pages.group_id = #{self.id}"
  end
    
end
