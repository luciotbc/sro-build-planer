require "application_system_test_case"

class SmokeTest < ApplicationSystemTestCase
  test "health check responds successfully" do
    visit rails_health_check_path
    assert_selector "body"
  end
end
