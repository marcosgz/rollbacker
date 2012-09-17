require File.dirname(__FILE__) + '/spec_helper'
require 'rollbacker/user'
require 'rollbacker/status'

describe Rollbacker::Base do
  include Rollbacker::Status

  before(:each) do
    @user = User.create
    @original_model = Model
    Rollbacker::User.current_user = @user
  end

  after(:each) do
    reset_model
  end

  it 'should be created a :create change record' do
    redefine_model { rollbacker!(:create) }

    m = Model.new(:name => 'new')
    m.should be_valid
    m.should be_changed
    lambda {
      lambda { m.save }.should change(RollbackerChange, :count).by(1)
    }.should_not change(Model, :count)

    verify_change(RollbackerChange.last, m, :create, { 'name' => [nil, 'new'], 'id' => [nil, m.id] })
  end

  it 'should be created a :update change record' do
    redefine_model { rollbacker!(:update) }
    m = Model.new(:name => 'new')
    without_rollbacker { m.save }

    lambda {
      lambda { m.update_attributes(:name => 'newer') }.should change(RollbackerChange, :count).by(1)
    }.should_not change(Model, :count)

    verify_change(RollbackerChange.last, m, :update, { 'name' => ['new', 'newer'] })
  end


  it 'should be created a :destroy change record' do
    redefine_model { rollbacker!(:destroy) }
    m = without_rollbacker { Model.create(:name => 'new') }

    lambda {
      lambda { m.destroy }.should change(RollbackerChange, :count).by(1)
    }.should_not change(Model, :count)

    verify_change(RollbackerChange.last, m, :destroy)
  end

  it 'should allow multiple actions to be specified with one rollbacker statment' do
    redefine_model { rollbacker!(:update, :destroy) }
    m = Model.new(:name => 'new')
    lambda {
      m.save
    }.should_not change(RollbackerChange, :count)
    m.should be_persisted
    lambda {
      m.update_attributes({:name => 'newer'})
    }.should change(RollbackerChange, :count).by(1)
    m.should be_persisted
    lambda {
      m.destroy
    }.should change(RollbackerChange, :count).by(1)

    RollbackerChange.count.should == 2
    edit1 = RollbackerChange.first
    edit1.action.should == 'update'
    edit2 = RollbackerChange.last
    edit2.action.should == 'destroy'
  end

  it 'should be able to turn off rollbacker for a especific field' do
    redefine_model { rollbacker!(:update, :except => :name) }

    m = Model.new(:name => 'name')
    lambda {
      m.save
    }.should_not change(RollbackerChange, :count)
    lambda {
      m.update_attributes({:name => 'new'})
    }.should_not change(RollbackerChange, :count)
    lambda {
      m.update_attributes({:value => 'new'})
    }.should change(RollbackerChange, :count).by(1)
  end

  it 'should be able to to track rollbacker changes for a especific field' do
    redefine_model { rollbacker!(:update, :only => :value) }

    m = Model.new(:name => 'name')
    lambda {
      m.save
    }.should_not change(RollbackerChange, :count)
    lambda {
      m.update_attributes({:name => 'new'})
    }.should_not change(RollbackerChange, :count)
    lambda {
      m.update_attributes({:value => 'new'})
    }.should change(RollbackerChange, :count).by(1)
  end

  def verify_change(change_record, model, action, changes=nil)
    change_record.should_not be_nil
    change_record.rollbackable_id.should     == model.id
    change_record.rollbackable_type.should   == model.class.to_s
    change_record.action.should              == action.to_s
    change_record.user.should                == @user
    change_record.rollbacked_changes.should  == changes.reject{|k,v|v.map(&:nil?).all?} unless changes.nil?
  end

  def redefine_model(&blk)
    clazz = Class.new(ActiveRecord::Base, &blk)
    Object.send :remove_const, 'Model'
    Object.send :const_set, 'Model', clazz
  end

  def reset_model
    Object.send :remove_const, 'Model'
    Object.send :const_set, 'Model', @original_model
  end

end
