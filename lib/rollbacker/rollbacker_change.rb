require 'active_record'
require 'rollbacker/config'
require 'rollbacker/status'

class RollbackerChange < ActiveRecord::Base
  include Rollbacker::Status
  belongs_to :rollbackable, :polymorphic => true
  belongs_to :user, :polymorphic => true

  before_create :set_user

  serialize :rollbacked_changes

  def new_attributes(*fields)
    (rollbacked_changes || {}).inject({}.with_indifferent_access) do |attrs,(attr,values)|
      attrs[attr] = values.is_a?(Array) ? values.last : values
      attrs
    end.select do |k,v|
      fields.blank? ? true : fields.map(&:to_s).include?(k)
    end
  end


  def reject(*fields)
    without_rollbacker do
      case self.action.to_s
      when 'update', 'create'
        update_changes_after_approve_or_reject(*fields)
      when 'destroy'
        self.rollbacked_changes = nil
        self.destroy
      end
    end
  end

  def approve(*fields)
    without_rollbacker do
      edits = self.new_attributes(*fields)
      case self.action.to_s
      when 'update'
        if edits.present? && self.rollbackable && self.rollbackable.update_attributes(edits)
          update_changes_after_approve_or_reject(*fields)
          return true
        end
      when 'create'
        if edits.present? && self.rollbackable_type.constantize.create(edits)
          self.rollbacked_changes = nil
          self.destroy
        end
      when 'destroy'
        if self.rollbackable && self.rollbackable.destroy
          self.rollbacked_changes = nil
          self.destroy
        end
      end
    end
  end

  def create_action?;   self[:action].to_s == 'create'   end
  def update_action?;   self[:action].to_s == 'update'   end
  def destroy_action?;  self[:action].to_s == 'destroy'  end

private
  def update_changes_after_approve_or_reject(*fields)
    edits = fields.blank? ? nil : rollbacked_changes.delete_if{|k,v| fields.map(&:to_s).include?(k) }
    if edits.present?
      self.update_attribute(:rollbacked_changes, edits)
    else
      self.rollbacked_changes = nil
      self.destroy
    end
  end

  def set_user
    self.user = Rollbacker::User.current_user if self.user_id.nil?
  end

end
