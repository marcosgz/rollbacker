module Rollbacker
  module SpecHelpers
    include Rollbacker::Status

    def self.included(base)
      base.class_eval do
        before(:each) do
          disable_rollbacker!
        end

        after(:each) do
          enable_rollbacker!
        end
      end
    end

  end
end


