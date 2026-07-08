require "test_helper"
require "zip"

class Users::ExportDataServiceTest < ActiveSupport::TestCase
  setup { @user = create(:user, :confirmed, email_opt_in: true) }

  def unzip(content)
    files = {}
    Zip::File.open_buffer(StringIO.new(content)) do |zip|
      zip.each { |entry| files[entry.name] = entry.get_input_stream.read }
    end
    files
  end

  test "builds a timestamped zip with user.csv excluding ids" do
    result = Users::ExportDataService.call(user: @user)

    assert result.success?
    assert_match(/\Asrolabs_\d{14}\.zip\z/, result.data[:filename])

    files = unzip(result.data[:content])
    assert_includes files.keys, "user.csv"

    rows = CSV.parse(files["user.csv"])
    header = rows.first
    assert_includes header, "email_address"
    assert_not_includes header, "id"
    assert_not_includes header, "uuid"
    assert_not_includes header, "password_digest"
    assert_includes rows.last, @user.email_address
  end

  test "exports one csv per character named race_name_level with build rows" do
    race = create(:race, name: "Chinese")
    mastery = create(:mastery, race: race, name: "Sword")
    group = create(:skill_group, mastery: mastery, name: "Cyclone")
    character = create(:character, user: @user, race: race, name: "BuckTBC")
    create(
      :character_mastery,
      character: character,
      mastery: mastery,
      current_mastery_level: 30,
      target_mastery_level: 60
    )
    create(
      :character_skill,
      character: character,
      skill_group: group,
      current_skill_level: 3,
      target_skill_level: 7
    )
    character.reload

    result = Users::ExportDataService.call(user: @user)
    files = unzip(result.data[:content])

    expected_name = "ch_BuckTBC_#{character.current_level}.csv"
    assert_includes files.keys, expected_name

    rows = CSV.parse(files[expected_name])
    assert_equal %w[
                   mastery_name
                   mastery_current_level
                   mastery_future_level
                   skill_group_name
                   current_skill_level
                   future_skill_level
                 ],
                 rows.first
    assert_equal %w[Sword 30 60 Cyclone 3 7], rows.second
  end

  test "suffixes duplicate character filenames" do
    race = create(:race, name: "Chinese")
    create(:character, user: @user, race: race, name: "Twin")
    create(:character, user: @user, race: race, name: "Twin")

    result = Users::ExportDataService.call(user: @user)
    files = unzip(result.data[:content])

    twin_files = files.keys.grep(/\Ach_Twin_\d+/)
    assert_equal 2, twin_files.length
    assert_equal twin_files.uniq.length, twin_files.length
  end

  test "a user without characters still gets a zip with only user.csv" do
    result = Users::ExportDataService.call(user: @user)
    files = unzip(result.data[:content])

    assert_equal ["user.csv"], files.keys
  end
end
