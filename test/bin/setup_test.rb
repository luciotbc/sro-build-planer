require "test_helper"
require "fileutils"
require "open3"
require "tmpdir"

class BinSetupTest < ActiveSupport::TestCase
  def run_setup(*args, rails_env: "development")
    Dir.mktmpdir("bin-setup-test") do |dir|
      app_root = Pathname.new(dir)
      bin_dir = app_root.join("bin")
      fake_path = app_root.join("fake-path")
      log_path = app_root.join("commands.log")

      FileUtils.mkdir_p([bin_dir, fake_path])
      FileUtils.cp(Rails.root.join("bin/setup"), bin_dir.join("setup"))
      write_executable(fake_path.join("bundle"), fake_bundle)
      write_executable(
        fake_path.join("oxipng"),
        "#!/usr/bin/env ruby\nexit 0\n"
      )
      write_executable(bin_dir.join("rails"), fake_rails)
      write_executable(bin_dir.join("dev"), "#!/usr/bin/env ruby\nexit 0\n")

      env = {
        "PATH" => "#{fake_path}:#{ENV.fetch("PATH")}",
        "RAILS_ENV" => rails_env,
        "SETUP_COMMAND_LOG" => log_path.to_s
      }

      stdout, stderr, status =
        Open3.capture3(env, RbConfig.ruby, bin_dir.join("setup").to_s, *args)

      commands = log_path.exist? ? log_path.read.lines.map(&:chomp) : []
      [commands, stdout, stderr, status]
    end
  end

  def write_executable(path, content)
    path.write(content)
    FileUtils.chmod("+x", path)
  end

  def fake_bundle
    <<~RUBY
      #!/usr/bin/env ruby
      exit(ARGV == ["check"] ? 0 : 1)
    RUBY
  end

  def fake_rails
    <<~RUBY
      #!/usr/bin/env ruby
      File.open(ENV.fetch("SETUP_COMMAND_LOG"), "a") do |file|
        file.puts(ARGV.join(" "))
      end
    RUBY
  end

  it "runs db:reset instead of db:prepare when reset is requested" do
    commands, _stdout, stderr, status = run_setup("--reset", "--skip-server")

    assert status.success?, stderr
    assert_equal ["db:reset", "log:clear tmp:clear"], commands
  end

  it "does not prepare or reset the database in production" do
    commands, _stdout, stderr, status =
      run_setup("--reset", "--skip-server", rails_env: "production")

    assert status.success?, stderr
    assert_empty commands
  end
end
