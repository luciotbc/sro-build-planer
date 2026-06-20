require "test_helper"

class Builds::SummaryServiceTest < ActiveSupport::TestCase
  before do
    @race = create(:race)
    @mastery_a = create(:mastery, race: @race)
    @mastery_b = create(:mastery, race: @race)
    @sg_a = create(:skill_group, mastery: @mastery_a)
    @sg_b = create(:skill_group, mastery: @mastery_b)

    # level_datum rows: sp_cumulative is the cost to bring ONE mastery to that level
    @ld_50 = create(:level_datum, level: 50, sp_cumulative: 1000)
    @ld_80 = create(:level_datum, level: 80, sp_cumulative: 2500)
    @ld_100 = create(:level_datum, level: 100, sp_cumulative: 5000)

    # skills: sp_cost is the incremental cost per level
    @skill_a1 = create(:skill, skill_group: @sg_a, skill_level: 1, sp_cost: 100)
    @skill_a2 = create(:skill, skill_group: @sg_a, skill_level: 2, sp_cost: 200)
    @skill_b1 = create(:skill, skill_group: @sg_b, skill_level: 1, sp_cost: 50)

    @char = create(:character, race: @race)
  end

  # --------- empty character --------------------------------------------------

  it "returns all zeros for a character with no masteries or skills" do
    result = Builds::SummaryService.call(@char)

    assert result.success?
    d = result.data
    assert_equal({ current: 0, planned: 0, delta: 0 }, d[:skill_points])
    assert_equal({ current: 0, planned: 0, delta: 0 }, d[:mastery_total])
    assert_equal({ current: 0, planned: 0, delta: 0 }, d[:required_level])
  end

  # --------- mastery SP (spec 02 R1) ----------------------------------------

  it "computes mastery SP as sum of sp_cumulative for each mastery's level" do
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_a,
      current_mastery_level: 50,
      target_mastery_level: 80
    )

    result = Builds::SummaryService.call(@char)

    d = result.data
    # current: sp_cumulative(50) = 1000
    assert_equal 1000, d[:skill_points][:current]
    # planned: sp_cumulative(80) = 2500
    assert_equal 2500, d[:skill_points][:planned]
  end

  it "sums mastery SP across multiple masteries including duplicates (R1a)" do
    # Two masteries both at level 50 — must count 1000 TWICE, not once (R1a)
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_a,
      current_mastery_level: 50,
      target_mastery_level: 50
    )
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_b,
      current_mastery_level: 50,
      target_mastery_level: 50
    )

    result = Builds::SummaryService.call(@char)

    assert_equal 2000,
                 result.data[:skill_points][:current],
                 "must NOT deduplicate equal mastery levels"
    assert_equal 2000, result.data[:skill_points][:planned]
  end

  it "treats missing level_datum as 0 and adds a warning" do
    # Use level 55 — within server_level_cap (110) but no LevelDatum exists for it
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_a,
      current_mastery_level: 55,
      target_mastery_level: 0
    )

    result = Builds::SummaryService.call(@char)

    assert result.success?
    assert_equal 0, result.data[:skill_points][:current]
    assert result.warnings.any? { |w| w.include?("55") }
  end

  # --------- skill SP (spec 02 R2) ------------------------------------------

  it "computes skill SP as cumulative sum of sp_cost from level 1..N" do
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_a,
      current_mastery_level: 50,
      target_mastery_level: 50
    )
    # current_skill_level: 2 → sp_cost(1) + sp_cost(2) = 100 + 200 = 300
    create(
      :character_skill,
      character: @char,
      skill_group: @sg_a,
      current_skill_level: 2,
      target_skill_level: 0
    )

    result = Builds::SummaryService.call(@char)

    skill_sp_current = result.data[:skill_points][:current] - 1000 # subtract mastery SP
    assert_equal 300, skill_sp_current
  end

  it "sums skill SP across multiple skills" do
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_a,
      current_mastery_level: 50,
      target_mastery_level: 50
    )
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_b,
      current_mastery_level: 50,
      target_mastery_level: 50
    )
    create(
      :character_skill,
      character: @char,
      skill_group: @sg_a,
      current_skill_level: 1,
      target_skill_level: 0
    )
    create(
      :character_skill,
      character: @char,
      skill_group: @sg_b,
      current_skill_level: 1,
      target_skill_level: 0
    )

    result = Builds::SummaryService.call(@char)

    # mastery SP: 1000 + 1000 = 2000; skill SP: 100 + 50 = 150; total current = 2150
    assert_equal 2150, result.data[:skill_points][:current]
  end

  it "treats skill_level 0 as zero skill SP" do
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_a,
      current_mastery_level: 50,
      target_mastery_level: 50
    )
    create(
      :character_skill,
      character: @char,
      skill_group: @sg_a,
      current_skill_level: 0,
      target_skill_level: 0
    )

    result = Builds::SummaryService.call(@char)

    assert_equal 1000, result.data[:skill_points][:current]
  end

  # --------- SKILL POINTS total / delta (spec 02 R3) ------------------------

  it "total SKILL POINTS = mastery SP + skill SP" do
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_a,
      current_mastery_level: 50,
      target_mastery_level: 80
    )
    create(
      :character_skill,
      character: @char,
      skill_group: @sg_a,
      current_skill_level: 1,
      target_skill_level: 2
    )

    result = Builds::SummaryService.call(@char)

    d = result.data
    assert_equal 1100, d[:skill_points][:current] # 1000 + 100 (sp_cost at level 1)
    assert_equal 2800, d[:skill_points][:planned] # 2500 + 300 (sp_cost levels 1+2 = 100+200)
    assert_equal 1700, d[:skill_points][:delta] # 2800 - 1100
  end

  it "delta may be negative when planned < current" do
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_a,
      current_mastery_level: 80,
      target_mastery_level: 50
    )

    result = Builds::SummaryService.call(@char)

    assert_equal(-1500, result.data[:skill_points][:delta])
  end

  # --------- MASTERY TOTAL (spec 02 R4) ------------------------------------

  it "mastery_total is sum of mastery levels" do
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_a,
      current_mastery_level: 50,
      target_mastery_level: 80
    )
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_b,
      current_mastery_level: 30,
      target_mastery_level: 100
    )

    result = Builds::SummaryService.call(@char)

    d = result.data
    assert_equal 80, d[:mastery_total][:current] # 50 + 30
    assert_equal 180, d[:mastery_total][:planned] # 80 + 100
    assert_equal 100, d[:mastery_total][:delta] # 180 - 80
  end

  # --------- REQUIRED LEVEL (spec 02 R5 / spec 01 R1) ---------------------

  it "required_level matches character current_level and target_level" do
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_a,
      current_mastery_level: 50,
      target_mastery_level: 80
    )
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_b,
      current_mastery_level: 30,
      target_mastery_level: 100
    )

    result = Builds::SummaryService.call(@char)

    d = result.data
    # current_level = MAX(50, 30) = 50; target_level = MAX(80, 100) = 100
    assert_equal 50, d[:required_level][:current]
    assert_equal 100, d[:required_level][:planned]
    assert_equal 50, d[:required_level][:delta]
  end

  # --------- return value shape --------------------------------------------

  it "returns a ServiceResult with data and warnings" do
    result = Builds::SummaryService.call(@char)

    assert result.success?
    assert_respond_to result, :data
    assert_respond_to result, :warnings
    assert_instance_of Hash, result.data
    assert_instance_of Array, result.warnings
  end

  # --------- N+1 guard (spec 003 acceptance criteria) ----------------------

  it "does not N+1 on masteries (uses at most 3 queries for masteries+skills+level_data)" do
    4.times do |i|
      m = create(:mastery, race: @race)
      sg = create(:skill_group, mastery: m)
      create(:level_datum, level: 10 + i, sp_cumulative: 100 * (i + 1))
      create(
        :character_mastery,
        character: @char,
        mastery: m,
        current_mastery_level: 10 + i,
        target_mastery_level: 10 + i
      )
      create(
        :character_skill,
        character: @char,
        skill_group: sg,
        current_skill_level: 0,
        target_skill_level: 0
      )
    end

    query_count = 0
    counter = ->(*, **) { query_count += 1 }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      Builds::SummaryService.call(@char)
    end

    assert query_count <= 4, "Expected at most 4 queries, got #{query_count}"
  end
end
