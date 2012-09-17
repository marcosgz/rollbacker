require 'active_record'
require 'rollbacker/config'

class RollbackerChange < ActiveRecord::Base
  belongs_to :rollbackable, :polymorphic => true
  belongs_to :user, :polymorphic => true

  before_create :set_user

  serialize :rollbacked_changes

  def new_attributes
    (rollbacked_changes || {}).inject({}.with_indifferent_access) do |attrs,(attr,values)|
      attrs[attr] = values.is_a?(Array) ? values.last : values
      attrs
    end
  end

private

  def set_user
    self.user = Rollbacker::User.current_user if self.user_id.nil?
  end

end
