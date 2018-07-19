require 'test_helper'

class MappingControllerTest < ActionDispatch::IntegrationTest
  test "should get list" do
    get mapping_list_url
    assert_response :success
  end

  test "should get new" do
    get mapping_new_url
    assert_response :success
  end

  test "should get create" do
    get mapping_create_url
    assert_response :success
  end

  test "should get edit" do
    get mapping_edit_url
    assert_response :success
  end

  test "should get update" do
    get mapping_update_url
    assert_response :success
  end

  test "should get delete" do
    get mapping_delete_url
    assert_response :success
  end

  test "should get approve" do
    get mapping_approve_url
    assert_response :success
  end

  test "should get approve_create" do
    get mapping_approve_create_url
    assert_response :success
  end

  test "should get reject" do
    get mapping_reject_url
    assert_response :success
  end

  test "should get reject_delete" do
    get mapping_reject_delete_url
    assert_response :success
  end

end
