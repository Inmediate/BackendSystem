require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get main" do
    get dashboard_main_url
    assert_response :success
  end

  test "should get setting" do
    get dashboard_setting_url
    assert_response :success
  end

  test "should get profile" do
    get dashboard_profile_url
    assert_response :success
  end

end
