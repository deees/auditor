module Auditor
  ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))
end

require 'auditor/command'
require 'auditor/source_updater'
require 'auditor/runner'
require 'auditor/cli'
