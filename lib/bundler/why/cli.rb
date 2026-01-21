# frozen_string_literal: true

require "thor"
require "bundler/why/dependency_resolver"

module Bundler
  module Why
    class CLI < Thor
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
          super(given_args, config)
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

        display_result(result, resolver)
      end

      def self.exit_on_failure?
        true
      end

      private

      def display_result(result, resolver)
        Bundler.ui.info("#{result[:name]} (#{result[:version]})")
        Bundler.ui.info("")

        # 依存関係チェーンを表示
        chains = resolver.find_dependency_chain(result[:name])
        
        if chains.any?
          Bundler.ui.info("Used by:")
          chains.each do |chain|
            chain_str = chain.join(" > ")
            Bundler.ui.info("  #{chain_str}")
          end
        else
          # 直接の依存元を表示
          direct_dependents = result[:direct_dependents]
          if direct_dependents.any?
            Bundler.ui.info("Directly required by:")
            direct_dependents.each do |dependent|
              Bundler.ui.info("  #{dependent[:name]} (#{dependent[:version]}) [#{dependent[:requirement]}]")
            end
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
        end

        Bundler.ui.info("")
        if result[:path]
          Bundler.ui.info("Location: #{result[:path]}")
        end
      end
    end
  end
end
