# frozen_string_literal: true

require_relative "lib/bundler/why/version"

Gem::Specification.new do |spec|
  spec.name = "bundler-why-plugin"
  spec.version = Bundler::Why::VERSION
  spec.authors = ["Hiroshi SHIBATA"]
  spec.email = ["hsbt@ruby-lang.org"]

  spec.summary = "Bundler plugin to show why a package is installed"
  spec.description = "A Bundler plugin that shows the dependency tree for a specific package, similar to 'yarn why' in Yarn."
  spec.homepage = "https://github.com/hsbt/bundler-why-plugin"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/hsbt/bundler-why-plugin"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "bundler", ">= 2.4.0"
  spec.add_dependency "thor", ">= 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
