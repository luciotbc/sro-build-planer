ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/spec"

module ActiveSupport
  class TestCase
    extend Minitest::Spec::DSL
    include FactoryBot::Syntax::Methods

    # Parallelism disabled: the Minitest::Spec DSL (describe/it) generates anonymous,
    # dynamically-named classes that fail to marshal across the DRb boundary used by
    # process-based parallelization, raising "RuntimeError: result not reported".
    # Run serially with PARALLEL_WORKERS=1 until the suite is large enough to justify
    # revisiting (e.g. thread-based parallelization).
    parallelize(workers: ENV.fetch("PARALLEL_WORKERS", 1).to_i)
  end
end
