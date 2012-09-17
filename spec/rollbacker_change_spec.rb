require File.dirname(__FILE__) + '/spec_helper'
require 'rollbacker/rollbacker_change'

describe RollbackerChange do
  before(:each) do
    @rollbackable = Model.create
    @user = User.create
  end

  it 'should provide access to the rollbacked model object' do
    record = RollbackerChange.create(:rollbackable => @rollbackable, :user => @user, :action => :create)
    record.rollbackable.should == @rollbackable
  end
  it 'should provide access to the user associated with the rollbacker_change' do
    record = RollbackerChange.create(:rollbackable => @rollbackable, :user => @user, :action => :create)
    record.user.should == @user
  end
end

