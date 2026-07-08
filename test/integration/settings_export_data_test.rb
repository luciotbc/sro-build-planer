require "test_helper"

class SettingsExportDataTest < ActionDispatch::IntegrationTest
  setup { @user = create(:user, :confirmed) }

  test "my data card shows the export button" do
    sign_in_as(@user)

    get settings_url

    assert_response :success
    assert_select "form[action=?] button", settings_export_path
  end

  test "clicking export enqueues the background job and shows a notice" do
    sign_in_as(@user)

    assert_enqueued_with(job: Users::ExportDataJob, args: [@user]) do
      post settings_export_url
    end

    assert_redirected_to settings_url
    follow_redirect! while response.redirect?
    assert_select "#toast-container", text: /export/i
  end

  test "unauthenticated export is redirected to login" do
    post settings_export_url

    assert_redirected_to new_session_url
  end
end
