require 'rollbacker/status'
require 'rollbacker/config'
require 'rollbacker/database_rollback'
require 'rollbacker/recorder'

module Rollbacker
  module Base

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def rollbacker(*args, &blk)
        unless self.included_modules.include?(ActiveRecord::Transactions::ClassMethods)
          include ActiveRecord::Transactions::ClassMethods
        end
        unless self.included_modules.include?(Rollbacker::Base::InstanceMethods)
          include InstanceMethods
          include Rollbacker::Status  unless self.included_modules.include?(Rollbacker::Status)
          has_many :rollbacker_changes, :as => :rollbackable
        end

        config = Rollbacker::Config.new(*args)
        config.actions.each do |action|
          send "before_#{action}", Rollbacker::DatabaseRollback.new(config.options)
          # send :after_rollback, Rollbacker::Recorder.new(action, config.options, &blk), :on => action
        end
        send :after_rollback, Rollbacker::Recorder.new(config.options, &blk)
      end

      def rollbacker!(*args, &blk)
        if args.last.kind_of?(Hash)
          args.last[:fail_on_error] = true
        else
          args << { :fail_on_error => true }
        end

        rollbacker(*args, &blk)
      end
    end

    module InstanceMethods
      attr_accessor :_rollbacker_action

    end

  end
end
