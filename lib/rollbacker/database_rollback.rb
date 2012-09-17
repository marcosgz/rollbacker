require 'rollbacker/status'
require 'rollbacker/change_validator'

module Rollbacker
  class DatabaseRollback
    include Status

    def initialize(args)
      @options = args
    end

    [:create, :update, :destroy].each do |action|
      define_method("before_#{action}") do |model|
        rollback_model_changes(model, action)
      end
    end

  private

    def rollback_model_changes(model, action)
      model._rollbacker_action = action

      if rollbacker_enabled? && ChangeValidator.new(action, @options, model).valid?
        raise ActiveRecord::Rollback
      end
    end
  end
end
