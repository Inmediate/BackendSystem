require 'test_helper'

class InsurerMappingControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get insurer_mapping_new_url
    assert_response :success
  end

  test "should get create" do
    get insurer_mapping_create_url
    assert_response :success
  end

  test "should get edit" do
    get insurer_mapping_edit_url
    assert_response :success
  end

  test "should get update" do
    get insurer_mapping_update_url
    assert_response :success
  end

  test "should get delete" do
    get insurer_mapping_delete_url
    assert_response :success
  end

end
