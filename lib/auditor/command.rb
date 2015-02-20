require 'open3'

module Auditor
  class Command
    def self.execute(command)
      Open3.popen3(command) do |_stdin, stdout, stderr, wait_thr|
        stdout_thread = Thread.new do
          while line = stdout.gets do
            puts line
          end
        end

        stderr_thread = Thread.new do
          while line = stderr.gets do
            puts "! #{line}"
          end
        end

        stdout_thread.join
        stderr_thread.join

        return wait_thr.value.to_i == 0
      end
    end
  end
end
