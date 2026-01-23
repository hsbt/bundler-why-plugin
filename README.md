# Bundler Why

A Bundler plugin that shows why a specific package is installed in your Ruby project, similar to `yarn why` in Yarn/npm.

This gem is a Bundler plugin that helps you understand the dependency tree of your gems and why a particular gem is required by your project.

## Installation

Install this plugin by running:

```bash
bundle plugin install bundler-why-plugin
```

To install from a local path during development:

```bash
bundle plugin install bundler-why-plugin --source /path/to/bundler-why-plugin
```

## Usage

To see why a specific package is installed:

```bash
bundle why <package_name>
```

### Example

```bash
❯ bundle why ffi
ffi (1.17.3)

Directly required by:
  ├── libddwaf (1.30.0.0.0) [~> 1.0]
  │     └── datadog (2.26.0) [~> 1.30.0.0.0]
  └── rb-inotify (0.11.1) [~> 1.0]
        └── listen (3.10.0) [~> 0.9, >= 0.9.10]

Location: /Users/hsbt/.local/share/gem/specifications/ffi-1.17.3-arm64-darwin.gemspec
```

## How It Works

The `bundle why` command performs the following:

1. **Parses your Gemfile.lock**: Loads the current bundle configuration
2. **Analyzes dependencies**: Traces which gems depend on the specified package
3. **Displays results**: Shows:
   - The gem's version number
   - Direct dependents (gems that directly require it)
   - All dependents (both direct and indirect)
   - The gem's installation location

## Features

- Shows direct dependents of a package
- Traces the full dependency chain
- Displays gem versions and requirement specifiers
- Handles both direct and transitive dependencies
- Clear, Yarn-like output format

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hsbt/bundler-why-plugin.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
