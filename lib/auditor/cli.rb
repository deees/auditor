require 'thor'

module Auditor
  class Cli < Thor
    desc 'check TARGET', 'run bundle-audit check on TARGET (default: all)'
    method_option :config, aliases: '-c'

    def check(target = :all)
      Runner.new(options).check(target)
    end
  end
end
