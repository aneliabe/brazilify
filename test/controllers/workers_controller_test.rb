require "test_helper"

class WorkersControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get workers_show_url
    assert_response :success
  end
end
