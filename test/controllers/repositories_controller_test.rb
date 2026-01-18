require "test_helper"

class RepositoriesControllerTest < ActionDispatch::IntegrationTest
  test "should get display" do
    get repositories_display_url
    assert_response :success
  end
end
