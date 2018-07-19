require 'test_helper'

class InsurerControllerTest < ActionDispatch::IntegrationTest
  test "should get list" do
    get insurer_list_url
    assert_response :success
  end

  test "should get new" do
    get insurer_new_url
    assert_response :success
  end

  test "should get create" do
    get insurer_create_url
    assert_response :success
  end

  test "should get edit" do
    get insurer_edit_url
    assert_response :success
  end

  test "should get update" do
    get insurer_update_url
    assert_response :success
  end

  test "should get delete" do
    get insurer_delete_url
    assert_response :success
  end

  test "should get approve" do
    get insurer_approve_url
    assert_response :success
  end

  test "should get approve_create" do
    get insurer_approve_create_url
    assert_response :success
  end

  test "should get reject" do
    get insurer_reject_url
    assert_response :success
  end

  test "should get reject_delete" do
    get insurer_reject_delete_url
    assert_response :success
  end

end
