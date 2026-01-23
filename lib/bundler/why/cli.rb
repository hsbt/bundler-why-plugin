# frozen_string_literal: true

# Use Bundler's vendored Thor instead of the standalone gem
require "bundler/vendored_thor"
require "bundler/why/dependency_resolver"

module Bundler
  module Why
    class CLI < Bundler::Thor
      # Allow running `bundle why <package>` without specifying the command name
      default_task :why

      # Thor expects the first arg to be a task name. Bundler passes only
      # the gem name (e.g. `minitest`), so route unknown commands to `why`.
      def self.start(given_args = ARGV, config = {})
        if given_args.empty?
          return super
        end

        first = given_args.first
        known = tasks.keys + %w[help]
        if known.include?(first)
          super
        else
          super(["why"] + given_args, config)
        end
      end

      desc "why PACKAGE", "Show why a specific package is installed"
      def why(package_name = nil)
        if package_name.nil?
          Bundler.ui.error("Error: Please specify a package name")
          Bundler.ui.error("Usage: bundle why <package_name>")
          exit 1
        end

        resolver = DependencyResolver.new
        result = resolver.analyze(package_name)

        unless result
          Bundler.ui.error("Error: Package '#{package_name}' not found in Gemfile.lock")
          exit 1
        end

        # ツリー構造を追加
        result[:dependents_tree] = resolver.build_dependents_tree(package_name)

        display_result(result, resolver)
      end

      def self.exit_on_failure?
        true
      end

      private

      def display_result(result, resolver)
        Bundler.ui.info("#{result[:name]} (#{result[:version]})")
        Bundler.ui.info("")

        # ツリー形式で依存関係を表示
        dependents_tree = result[:dependents_tree]
        if dependents_tree.any?
          Bundler.ui.info("Directly required by:")
          display_tree(dependents_tree, "")
        else
          Bundler.ui.info("Required by:")
          all_dependents = result[:all_dependents]
          if all_dependents.any?
            all_dependents.each do |dependent|
              Bundler.ui.info("  #{dependent[:name]} (#{dependent[:version]})")
            end
          else
            Bundler.ui.warn("Not required by any other packages (may be a direct dependency)")
          end
        end

        Bundler.ui.info("")
        if result[:path]
          Bundler.ui.info("Location: #{result[:path]}")
        end
      end

      def display_tree(items, prefix = "")
        items.each_with_index do |item, index|
          is_last = index == items.length - 1
          current_prefix = is_last ? "  └── " : "  ├── "
          next_prefix = is_last ? "      " : "  │   "

          Bundler.ui.info("#{prefix}#{current_prefix}#{item[:name]} (#{item[:version]}) [#{item[:requirement]}]")

          if item[:children] && item[:children].any?
            display_tree(item[:children], prefix + next_prefix)
          end
        end
      end
    end
  end
end
