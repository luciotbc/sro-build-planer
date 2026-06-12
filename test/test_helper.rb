ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require "minitest/spec"

module ActiveSupport
  class TestCase
    extend Minitest::Spec::DSL
    include FactoryBot::Syntax::Methods

    # Parallel (forked) runs hang: describe-block classes are anonymous and
    # cannot be marshaled over DRb (rails/rails#39021), so workers crash and
    # the master waits forever. The suite runs in ~3s serially.
    parallelize(workers: 1)
  end
end
