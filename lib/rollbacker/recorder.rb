require 'rollbacker/status'

module Rollbacker
  class Recorder
    include Status

    # def initialize(action, options, &blk)
    #   @action  = action
    #   @options = options
    #   @blk     = blk
    # end

    def initialize(options, &blk)
      @options = options
      @blk     = blk
    end

    def after_rollback(model)
      create_or_update_changes(model)
    end

  private
    # Should just return @action if after_rollback(:on=>:destroy) should set the correct action.. Take a look at this issue:
    # https://github.com/rails/rails/issues/7640
    #
    # **Also remove everything about _rollbacker_action instance method.**
    #
    # def action
    #   @action
    # end

    def change_validator(model)
      ChangeValidator.new(model._rollbacker_action, @options, model)
    end

    def create_or_update_changes(model)
      return if rollbacker_disabled?
      validator = change_validator(model)
      return unless validator.valid?
      user = Rollbacker::User.current_user

      record = \
        if model.new_record?
          RollbackerChange.new(rollbackable_type: model.class.name, action: validator.action)
        else
          RollbackerChange.find_or_initialize_by_rollbackable_id_and_rollbackable_type_and_action(model.id, model.class.name, validator.action)
        end
      if model.changed?
        record.rollbacked_changes = validator.changes(record.rollbacked_changes)
      end

      @blk.call(model, record, user, validator.action) if @blk

      @options[:fail_on_error] ? record.save! : record.save
    end
  end
end
