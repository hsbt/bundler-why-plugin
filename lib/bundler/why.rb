# frozen_string_literal: true

require "bundler"
require_relative "why/version"
require_relative "why/cli"
require_relative "why/dependency_resolver"

module Bundler
  module Why
    class Error < StandardError; end
  end
end
