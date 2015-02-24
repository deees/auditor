require 'yaml'
require 'bundler/audit'
require 'bundler/audit/scanner'

module Auditor
  class Runner
    class Result
      attr_accessor :target, :failures, :vulnerabilities
      def initialize(target)
        @target = target
        @failures, @vulnerabilities = [], []
      end
    end

    def initialize(options)
      @options = options
    end

    def check(target = :all)
      update_advisories

      projects(target).map do |project, repo_url|
        check_single(project, repo_url)
      end
    end

    def check_single(target, repo_url)
      Result.new(target).tap do |result|
        project_root = project_root(target)
        if SourceUpdater.new(project_root, repo_url).update!
          result.vulnerabilities = vulnerabilities(project_root).to_a
        else
          result.failures << 'Source update FAILED!'
        end
      end
    end

    def project_root(target)
      File.expand_path(File.join(ROOT, '.source', target.to_s))
    end

    def configuration
      @configuration ||= begin
        file = File.expand_path(configuration_file)
        puts "Using projects configuration from #{file}"
        YAML.load_file(file)
      end
    end

    def configuration_file
      @options['config'] || File.join(ROOT, 'config', 'projects.yml')
    end

    def configuration_for_project(target)
      configuration.select { |project, _| project == target }
    end

    def projects(target)
      target == :all ? configuration : configuration_for_project(target)
    end

    def update_advisories
      puts 'Updating ruby-advisory-db ...'
      Bundler::Audit::Database.update!
      puts "ruby-advisory-db: #{Bundler::Audit::Database.new.size} advisories"
    end

    def vulnerabilities(project_root)
      puts "Checking for vulnerabilities in #{project_root} with 'bundle-audit'..."
      Bundler::Audit::Scanner.new(project_root).scan
    end
  end
end
