require 'test_helper'

class ClientApiControllerTest < ActionDispatch::IntegrationTest
  test "should get list" do
    get client_api_list_url
    assert_response :success
  end

  test "should get new" do
    get client_api_new_url
    assert_response :success
  end

  test "should get edit" do
    get client_api_edit_url
    assert_response :success
  end

  test "should get create" do
    get client_api_create_url
    assert_response :success
  end

  test "should get update" do
    get client_api_update_url
    assert_response :success
  end

end
