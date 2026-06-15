require "application_system_test_case"

class InteractionsTest < ApplicationSystemTestCase
  include FactoryBot::Syntax::Methods

  # ---------------------------------------------------------------------------
  # Shared helper: sign in via the session form (browser-based, no cookie hack)
  # ---------------------------------------------------------------------------
  def system_sign_in(user, password: "password123")
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: password
    click_on "Sign in"
    # Wait until the redirect away from the sign-in page completes before
    # proceeding; Capybara would otherwise read the page mid-redirect.
    assert_no_current_path new_session_path, wait: 5
  end

  # ---------------------------------------------------------------------------
  # Test 1: Characters drawer -- open / close via backdrop click
  # ---------------------------------------------------------------------------
  test "characters drawer opens and closes via backdrop click" do
    race = create(:race, :chinese)
    user = create(:user)
    create(:character, user: user, race: race)

    system_sign_in(user)

    visit root_path

    # The characters pill link loads the drawer inside the "modal" turbo-frame.
    find("a", text: "Characters").click

    assert_selector "dialog[open]", wait: 5

    # The <dialog> element handles backdrop clicks via the Stimulus dialog
    # controller's backdropClose action. The drawer panel occupies the right
    # side of the viewport (420 px) so an absolute click at x=50 (far left)
    # falls on the ::backdrop, which the browser routes as a click on the
    # <dialog> element itself -- exactly what backdropClose expects.
    page.driver.browser.action.move_to_location(50, 400).click.perform

    assert_no_selector "dialog[open]", wait: 5
  end

  # ---------------------------------------------------------------------------
  # Test 2: Characters drawer -- close via the x button
  # ---------------------------------------------------------------------------
  test "characters drawer closes via close button" do
    race = create(:race, :european)
    user = create(:user)
    create(:character, user: user, race: race)

    system_sign_in(user)

    visit root_path

    find("a", text: "Characters").click

    assert_selector "dialog[open]", wait: 5

    find("button[aria-label='Close']").click

    assert_no_selector "dialog[open]", wait: 5
  end

  # ---------------------------------------------------------------------------
  # Test 3: Create character via modal
  # ---------------------------------------------------------------------------
  test "user can create a character via the new character modal" do
    create(:race, :chinese)
    create(:race, :european)
    user = create(:user)

    system_sign_in(user)

    visit root_path

    # Authenticated but no characters -> "+ New character" button visible
    click_on "+ New character"

    # Wait for the modal to open inside the turbo-frame
    assert_selector "dialog[open]", wait: 5

    # Use the field name attribute because i18n labels are rendered
    # via t(".label_name") which requires the locale to resolve correctly
    # server-side; targeting by name is more robust in tests.
    fill_in "character[name]", with: "My Test Hero"

    # Select the first race radio (Chinese) -- click its label
    find("label", text: /Chinese/i).click

    # Select level cap 110 -- it is pre-checked by default, but click it anyway
    find("label", text: /110/i).click

    # Submit via the input[type=submit] since its value may not match the
    # I18n key in the test server context.
    find("dialog[open] input[type=submit]").click

    # After successful create, redirected to root; the char_bar renders the
    # new character's name inside the identity bar above the skill sections.
    assert_text "My Test Hero", wait: 5
  end

  # ---------------------------------------------------------------------------
  # Test 4: Mastery type tab switching
  # ---------------------------------------------------------------------------
  test "mastery type tab switching updates the skill window" do
    skip "requires imported mastery data with multiple mastery types assigned " \
           "to a character via CharacterMastery; the factory chain for " \
           "SkillSeries and SkillGroup is available but the Characters::SkillWindow " \
           "service requires at least one SkillGroup per mastery and at least two " \
           "distinct mastery_type values (e.g. Weapon + Force) linked to the " \
           "character's race to produce visible pill tabs. Seed the DB with " \
           "bin/rails import:skills_xml and then run this test against that data."
  end
end
