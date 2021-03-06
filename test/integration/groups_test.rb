require File.dirname(__FILE__) + '/../test_helper'

class GroupsTest < ActionController::IntegrationTest
  def test_join_network_we_have_access_to
    login 'penguin'
    visit '/fau'

    assert_contain I18n.t(:join_group_link, :group_type => 'Network').upcase

    assert_difference 'Membership.count' do
      click_link I18n.t(:join_group_link, :group_type => 'Network').upcase 
    end
  end

  def test_create_page_link_if_member
    login 'blue'
    visit '/rainbow'
    assert_contain I18n.t(:contribute_content_link).upcase 
  end

  def test_join_link_if_not_member
    login 'penguin'
    visit '/public_group_everyone_can_see+public_committee'
    assert_contain I18n.t(:join_group_link, :group_type => 'Committee').upcase
  end

  def test_change_group_membership_policy
    login 'blue'
    visit '/rainbow'
    click_link 'ADMINISTRATION'
    click_link 'Permissions'

    check 'Allow Membership Requests'
    check 'Open Group'
    click_button 'Save'
    assert_contain 'Changes saved'

    login 'aaron'
    visit '/rainbow'

    click_link I18n.t(:join_group_link, :group_type => 'Group').upcase 
    assert_contain 'Leave Group'

    # disable open group. should change what users see
    login 'blue'
    visit '/rainbow'
    click_link 'ADMINISTRATION'
    click_link 'Permissions'

    check 'Allow Membership Requests'
    uncheck 'Open Group'
    click_button 'Save'
    assert_contain 'Changes saved'

    login 'aaron'
    visit '/rainbow'
    click_link 'Leave Group'
    click_button 'Leave'

    click_link I18n.t(:request_join_group_link, :group_type => 'Group').upcase
    click_button 'Send Request'
    assert_contain 'Request to join has been sent'
  end

  def test_do_not_show_announcements
    login 'red'
    visit "/the-true-levellers"
    assert_not_contain "Announcements"
  end


end
