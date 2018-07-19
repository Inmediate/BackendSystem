require 'test_helper'

class InsurerProductApiControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get insurer_product_api_new_url
    assert_response :success
  end

  test "should get edit" do
    get insurer_product_api_edit_url
    assert_response :success
  end

end
