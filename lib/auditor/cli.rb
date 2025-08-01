require 'thor'
require 'bundler/audit/cli'

require 'ext/thor/shell/color'
require 'ext/bundler/audit/cli'

module Auditor
  class Cli < Thor
    attr_reader :failed

    def initialize(*args)
      super
      @failed = {}
    end

    desc 'check TARGET', 'run bundle-audit check on TARGET (default: all)'
    method_option :config, aliases: '-c'

    def check(target = :all)
      Runner.new(options).check(target).each do |result|
        project = result.target

        say "#{project} ", [:blue, :bold]
        say '-' * (74 - project.length), :blue

        ignore_advisories = result.ignore_advisories
        print_ignored_advisories(ignore_advisories) unless ignore_advisories.empty?

        failures = result.failures
        print_failures(project, failures) unless failures.empty?

        vulnerabilities = result.vulnerabilities
        print_vulnerabilities(project, vulnerabilities) unless vulnerabilities.empty?

        print_audit_conclusion(project)
      end

      unless failed.empty?
        say '-' * 75, :blue
        say "*** VULNERABLE PROJECTS: #{failed.keys} (see above for details)", :red
        exit status_by_failures
      end
    end

    protected

    def print_ignored_advisories(ignore_advisories)
      say "Ignoring: #{ignore_advisories.join(', ')}...", :yellow
      say
    end

    def print_failures(project, failures)
      mark_as_failed(project, :git)
      failures.each do |failure|
        say failure, :red
      end
    end

    def print_vulnerabilities(project, vulnerabilities)
      extend Bundler::Audit::CLI::Formats.load(:text)

      vulnerabilities.each do |vulnerability|
        case vulnerability
        when Bundler::Audit::Results::InsecureSource
          mark_as_failed(project, :insecure_source)
          say "Insecure Source URI found: #{vulnerability.source}", :yellow
        when Bundler::Audit::Results::UnpatchedGem
          mark_as_failed(project, :unpatched_gem)
          print_advisory(vulnerability.gem, vulnerability.advisory)
        end
      end
    end

    def print_audit_conclusion(project)
      if failed[project]
        say 'Vulnerabilities found!', :red if vulnerable?(project)
      else
        say 'No vulnerabilities found', :green
      end
    end

    def mark_as_failed(project, reason)
      @failed[project] = reason
    end

    def vulnerable?(project)
      [:insecure_source, :unpatched_gem].include?(failed[project])
    end

    def status_by_failures
      @failed.key(:unpatched_gem).nil? ? 0 : 1
    end
  end
end
