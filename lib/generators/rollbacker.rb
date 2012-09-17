module Rollbacker
  module Generators
    class Base < Rails::Generators::NamedBase
      def self.source_root
        File.expand_path(File.join(File.dirname(__FILE__), 'rollbacker', generator_name, 'templates'))
      end
    end
  end
end