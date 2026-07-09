require "test_helper"

class LegalPagesTest < ActionDispatch::IntegrationTest
  test "privacy policy is public and renders its content" do
    get privacy_url

    assert_response :success
    assert_select "h1.legal-title", text: "Privacy Policy"
    assert_select ".legal h2", text: "Cookie Policy for SRO Lab"
  end

  test "privacy renders in Portuguese under a pt-BR request" do
    get privacy_url, headers: { "Accept-Language" => "pt-BR" }

    assert_response :success
    assert_select ".legal h2", text: "Compromisso do Usuário"
  end

  test "unsupported locales fall back to English privacy" do
    get privacy_url, headers: { "Accept-Language" => "ko" }

    assert_response :success
    assert_select ".legal h2", text: "Cookie Policy for SRO Lab"
  end

  test "terms of service is public and renders its content" do
    get terms_url

    assert_response :success
    assert_select "h1.legal-title", text: "Terms of Service"
    assert_select ".legal h2", text: "1. Terms"
  end

  test "terms render in Portuguese under a pt-BR request" do
    get terms_url, headers: { "Accept-Language" => "pt-BR" }

    assert_response :success
    assert_select ".legal h2", text: "1. Termos"
  end

  test "unsupported locales fall back to English terms" do
    get terms_url, headers: { "Accept-Language" => "ko" }

    assert_response :success
    assert_select ".legal h2", text: "1. Terms"
  end
end
