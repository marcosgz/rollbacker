class User < ActiveRecord::Base; end
class Model < ActiveRecord::Base
  belongs_to :user
end

class MyModel < ActiveRecord::Base
  include ActiveRecord::Transactions::ClassMethods
  self.table_name = 'models'

  before_create  :raise_rollback!, :unless => :skip_before_create
  before_destroy :raise_rollback!
  before_update  :raise_rollback!
  after_rollback(:on => :create){|record| record.send(:do_after_rollback, :create)}
  after_rollback(:on => :update){|record| record.send(:do_after_rollback, :update)}
  after_rollback(:on => :destroy){|record| record.send(:do_after_rollback, :destroy)}
  attr_accessor :skip_before_create

  def history
    @history ||= []
  end
private
  def raise_rollback!
    raise ActiveRecord::Rollback
  end

  def do_after_rollback(on)
    history << "after_rollback_on_#{on}"
  end
end
