module Auditor
  class SourceUpdater
    attr_reader :project_root, :repo_url

    def initialize(project_root, repo_url)
      @project_root = project_root
      @repo_url = repo_url
    end

    def update!
      cloned? ? pull! : clone!
    end

    def cloned?
      File.exist?(File.join(project_root, '.git'))
    end

    def clone!
      puts "Cloning code to #{project_root}..."
      Command.execute("git clone --depth 1 #{repo_url} #{project_root}")
    end

    def pull!
      puts "Pulling updates to #{project_root}..."
      Command.execute("cd #{project_root}; git pull origin master")
    end
  end
end
