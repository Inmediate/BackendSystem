require 'test_helper'

class LogControllerTest < ActionDispatch::IntegrationTest
  test "should get product_api" do
    get log_product_api_url
    assert_response :success
  end

  test "should get client_api" do
    get log_client_api_url
    assert_response :success
  end

  test "should get approval" do
    get log_approval_url
    assert_response :success
  end

  test "should get session_history" do
    get log_session_history_url
    assert_response :success
  end

end
