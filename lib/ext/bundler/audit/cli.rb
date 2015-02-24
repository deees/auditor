module Bundler
  module Audit
    class CLI
      protected

      def say(message = '', color = nil)
        super(message.to_s, color)
      end
    end
  end
end
