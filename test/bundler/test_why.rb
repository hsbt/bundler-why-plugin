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
end
