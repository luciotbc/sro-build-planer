class ServiceResult
  attr_reader :data, :warnings, :errors

  def initialize(success:, data: nil, warnings: [], errors: [])
    @success = success
    @data = data
    @warnings = warnings.freeze
    @errors = errors.freeze
  end

  def success? = @success

  def self.ok(data: nil, warnings: []) = new(success: true, data:, warnings:)
  def self.fail(errors:, warnings: []) = new(success: false, errors:, warnings:)
end
