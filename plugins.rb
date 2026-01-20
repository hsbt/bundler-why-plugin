require "bundler"
require "bundler/why"

module Bundler
  module Why
    class Plugin < ::Bundler::Plugin::API
      command "why"

      def exec(command_name, args)
        ::Bundler::Why::CLI.start(args)
      end
    end
  end
end
