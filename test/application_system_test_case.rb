require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  # System tests run Puma in a separate thread. Transactional fixtures wrap
  # test data in an uncommitted transaction invisible to the server thread,
  # causing sign-in to fail (user not found). Disable transactions and clean
  # the test database via deletion after each system test instead.
  self.use_transactional_tests = false

  teardown { DatabaseHelper.clean_all! }
end

# Minimal truncation helper (no gem dependency -- just DELETE FROM each table).
module DatabaseHelper
  TABLES = %w[
    character_masteries
    character_skills
    characters
    sessions
    users
    skill_group_requirements
    skills
    skill_groups
    skill_series
    masteries
    level_data
    races
  ].freeze

  def self.clean_all!
    ApplicationRecord.connection.disable_referential_integrity do
      TABLES.each do |table|
        ApplicationRecord.connection.execute("DELETE FROM #{table}")
      end
    end
  end
end
