require 'yaml'
require 'bundler/audit'

module Auditor
  class Runner
    def initialize(options)
      @options = options
    end

    def check(target = :all)
      update_advisories

      vulnerable = []
      failed = false

      projects(target).each do |project, repo_url|
        puts '*' * 75
        project_root = project_root(project)
        success = SourceUpdater.new(project_root, repo_url).update!
        if success
          puts '-' * 75
          no_vulnerabilities = audit!(project_root)
          vulnerable << project unless no_vulnerabilities
        else
          puts "Source update FAILED!"
          failed = true
        end
      end

      return true if vulnerable.empty? && !failed

      puts "\n\nVULNERABLE PROJECTS: #{vulnerable} (see above for details)"
      return false
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

    def audit!(project_root)
      puts "Checking for vulnerabilities in #{project_root} with 'bundle-audit'..."
      Command.execute("cd #{project_root}; bundle-audit")
    end
  end
end
