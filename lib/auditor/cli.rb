require 'thor'

module Auditor
  class Cli < Thor
    desc 'check TARGET', 'run bundle-audit check on TARGET (default: all)'
    method_option :config, aliases: '-c'

    def check(target = :all)
      status = Runner.new(options).check(target) ? 0 : 1
      exit status
    end
  end
end
