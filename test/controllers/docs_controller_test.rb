require "test_helper"

class DocsControllerTest < ActionDispatch::IntegrationTest
  # The design system route is only drawn in development, so outside it the path
  # must not resolve to any controller action.
  test "design_system route is not available outside development" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/docs/design_system")
    end
  end
end
