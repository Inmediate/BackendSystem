require 'test_helper'

class ClientControllerTest < ActionDispatch::IntegrationTest
  test "should get list" do
    get client_list_url
    assert_response :success
  end

  test "should get new" do
    get client_new_url
    assert_response :success
  end

  test "should get create" do
    get client_create_url
    assert_response :success
  end

  test "should get edit" do
    get client_edit_url
    assert_response :success
  end

  test "should get update" do
    get client_update_url
    assert_response :success
  end

  test "should get delete" do
    get client_delete_url
    assert_response :success
  end

  test "should get approve" do
    get client_approve_url
    assert_response :success
  end

  test "should get approve_create" do
    get client_approve_create_url
    assert_response :success
  end

  test "should get reject" do
    get client_reject_url
    assert_response :success
  end

  test "should get reject_delete" do
    get client_reject_delete_url
    assert_response :success
  end

end
