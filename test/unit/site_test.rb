require File.dirname(__FILE__) + '/../test_helper'

class Site < ActiveRecord::Base
  def self.uncache_default
    @default_size = nil
  end
end

class SiteTest < Test::Unit::TestCase
  fixtures :sites, :users, :groups, :memberships

  def test_defaults_to_conf
    assert_equal Conf.title, Site.new.title
  end

  def test_site_admin
    blue = users(:blue)
    kangaroo = users(:kangaroo)
    site = Site.find_by_name("site1")
    admins = Council.create! :name => 'admins'
    site.network.add_committee!(admins, true)
    admins.add_user! blue
    assert blue.may?(:admin, site), 'blue should have access to the first site.'
    assert !kangaroo.may?(:admin, site), 'kangaroo should not have :admin access to the first site.'
    # if no council is set no one may :admin
    site.network.council.destroy
    site.network.reload
    blue.clear_access_cache
    assert_raises(PermissionDenied, 'blue should not have :admin access to the first site anymore.') do
      blue.may!(:admin, site)
    end
  end

end
