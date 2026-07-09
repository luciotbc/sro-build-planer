require "test_helper"

class SharedBuildsControllerTest < ActionDispatch::IntegrationTest
  before do
    @user = create(:user)
    @race = create(:race, name: "Chinese")
    @char =
      create(
        :character,
        user: @user,
        race: @race,
        name: "Blade Lord",
        public: true
      )
    @mastery = create(:mastery, race: @race, name: "Blade")
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery,
      current_mastery_level: 40,
      target_mastery_level: 90
    )
  end

  # ---- public access ---------------------------------------------------------

  it "renders the shared build page for an unauthenticated visitor" do
    get shared_build_path(@char.share_token)
    assert_response :success
    assert_includes response.body, "Blade Lord"
    assert_includes response.body, @mastery.name
  end

  it "shows the share link on the page" do
    get shared_build_path(@char.share_token)
    assert_includes response.body, shared_build_url(@char.share_token)
  end

  it "renders the stats summary" do
    get shared_build_path(@char.share_token)
    assert_select ".stat-merged"
  end

  it "returns 404 for an unknown share token" do
    get shared_build_path("00000000-0000-0000-0000-000000000000")
    assert_response :not_found
  end

  # ---- visibility gate (spec 05 R11a/R12) ------------------------------------

  it "returns 404 for a private character even with a valid token" do
    private_char =
      create(
        :character,
        user: @user,
        race: @race,
        name: "Secret",
        public: false
      )
    get shared_build_path(private_char.share_token)
    assert_response :not_found
  end

  it "renders the build once the owner makes it public" do
    private_char = create(:character, user: @user, race: @race, name: "Secret")
    private_char.update!(public: true)
    get shared_build_path(private_char.share_token)
    assert_response :success
    assert_includes response.body, "Secret"
  end

  # ---- read-only guarantee ---------------------------------------------------

  it "contains no edit affordances" do
    get shared_build_path(@char.share_token)
    refute_includes response.body, edit_character_path(@char)
    # No mutating forms inside the page content (topbar auth modals excluded).
    assert_select "main form", count: 0
    assert_select "main .stepper", count: 0
  end

  it "keeps mastery navigation on the shared route" do
    get shared_build_path(@char.share_token)
    assert_includes response.body,
                    shared_build_path(
                      @char.share_token,
                      mastery_id: @mastery.id
                    )
    refute_includes response.body, character_path(@char)
  end

  # ---- OG meta tags ----------------------------------------------------------

  it "renders OG tags with title, race crest image, and mastery description" do
    get shared_build_path(@char.share_token)
    assert_select "meta[property='og:title'][content='Blade Lord']"
    assert_select "meta[property='og:url'][content=?]",
                  shared_build_url(@char.share_token)
    assert_select "meta[property='og:image']" do |imgs|
      assert_match /china.*\.png/, imgs.first[:content]
      assert_match %r{\Ahttps?://}, imgs.first[:content]
    end
    assert_select "meta[property='og:description']" do |descs|
      assert_includes descs.first[:content], "#{@mastery.name} 40 → 90"
    end
  end

  it "renders empty-safe OG description for a character without masteries" do
    empty_char =
      create(:character, user: @user, race: @race, name: "Fresh", public: true)
    get shared_build_path(empty_char.share_token)
    assert_response :success
    assert_select "meta[property='og:title'][content='Fresh']"
  end
end
