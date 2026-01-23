# frozen_string_literal: true

require "test_helper"

class Bundler::TestWhy < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Bundler::Why::VERSION
  end

  def test_version_format
    assert_match(/^\d+\.\d+\.\d+$/, ::Bundler::Why::VERSION)
  end

  def test_dependency_resolver_initializes
    resolver = ::Bundler::Why::DependencyResolver.new
    refute_nil resolver
  end

  def test_error_class_exists
    assert_kind_of Class, ::Bundler::Why::Error
    assert ::Bundler::Why::Error < StandardError
  end

  def test_cli_class_exists
    assert_kind_of Class, ::Bundler::Why::CLI
  end

  # Real package dependency tests
  def test_find_spec_for_minitest
    resolver = ::Bundler::Why::DependencyResolver.new
    spec = resolver.find_spec("minitest")

    refute_nil spec
    assert_equal "minitest", spec.name
  end

  def test_analyze_minitest_returns_correct_structure
    resolver = ::Bundler::Why::DependencyResolver.new
    result = resolver.analyze("minitest")

    refute_nil result
    assert_equal "minitest", result[:name]
    assert result[:version].match?(/^\d+\.\d+\.\d+/)
    assert_kind_of Array, result[:direct_dependents]
    assert_kind_of Array, result[:all_dependents]
  end

  def test_minitest_is_in_gemfile_dependencies
    resolver = ::Bundler::Why::DependencyResolver.new
    gemfile_deps = resolver.gemfile_dependencies

    assert gemfile_deps.include?("minitest"),
      "minitest should be listed in Gemfile dependencies"
  end

  def test_find_dependency_chain_for_minitest
    resolver = ::Bundler::Why::DependencyResolver.new

    # minitest is a direct dependency in Gemfile
    gemfile_deps = resolver.gemfile_dependencies
    assert gemfile_deps.include?("minitest"),
      "minitest should be a direct Gemfile dependency"

    # When a package is a direct dependency, it may not have a dependency chain
    # since it's already at the top level. Just verify the method doesn't error.
    chains = resolver.find_dependency_chain("minitest")
    assert_kind_of Array, chains,
      "find_dependency_chain should return an array"
  end

  def test_analyze_returns_minitest_path
    resolver = ::Bundler::Why::DependencyResolver.new
    result = resolver.analyze("minitest")

    refute_nil result[:path]
    assert result[:path].include?("minitest"),
      "path should include minitest"
  end

  # CLI display tests
  def test_cli_why_displays_package_info
    cli = ::Bundler::Why::CLI.new
    output = capture_stdout do
      cli.why("minitest")
    end

    assert output.include?("minitest"),
      "output should include package name"
    assert output.include?("Dependency chain:") || output.include?("Directly required by:") || output.include?("Required by:"),
      "output should include dependency information"
  end

  def test_cli_why_displays_version
    cli = ::Bundler::Why::CLI.new
    output = capture_stdout do
      cli.why("minitest")
    end

    # Should display version number (format: package_name (version))
    assert output.match?(/minitest\s+\(\d+\.\d+\.\d+\)/),
      "output should include package name and version"
  end

  def test_cli_why_displays_location
    cli = ::Bundler::Why::CLI.new
    output = capture_stdout do
      cli.why("minitest")
    end

    assert output.include?("Location:"),
      "output should include Location information"
  end

  def test_cli_why_with_invalid_package
    cli = ::Bundler::Why::CLI.new
    error_output = capture_stderr do
      cli.why("nonexistent_package_xyz_12345")
    rescue SystemExit
      # CLI may exit, which is expected
    end

    assert error_output.include?("not found"),
      "error output should indicate package not found"
  end

  private

  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end

  def capture_stderr
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = old_stderr
  end
end
