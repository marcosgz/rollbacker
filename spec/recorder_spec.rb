require File.dirname(__FILE__) + '/spec_helper'
require 'rollbacker/user'

describe Rollbacker::Recorder do

  before(:each) do
    @user = Rollbacker::User.current_user = User.create
  end

  [:create, :update].each do |action|
    it "should NOT be created an rollbacker_change record for #{action} actions if no changes" do
      model = Model.new
      model.stub(:_rollbacker_action).and_return(action)
      model.save if action.eql?(:update)

      config = Rollbacker::Config.new(action)
      # recorder = Rollbacker::Recorder.new(action, config.options)
      recorder = Rollbacker::Recorder.new(config.options)

      lambda {
        recorder.send "after_rollback", model
      }.should_not change(RollbackerChange, :count)
    end
  end

  [:destroy, :update].each do |action|
    it "should NOT be created change record for #{action} actions if model is a new record" do
      model = Model.new
      model.stub(:_rollbacker_action).and_return(action)

      config = Rollbacker::Config.new(action)
      # recorder = Rollbacker::Recorder.new(action, config.options)
      recorder = Rollbacker::Recorder.new(config.options)

      lambda {
        recorder.send "after_rollback", model
      }.should_not change(RollbackerChange, :count)
    end
  end

  describe "on :create" do
    let(:action) { :create }
    it "should be create the change record after model rollback" do
      model = Model.new(name: "Changed")
      model.stub(:_rollbacker_action).and_return(action)
      config = Rollbacker::Config.new(action)

      # recorder = Rollbacker::Recorder.new(action, config.options)
      recorder = Rollbacker::Recorder.new(config.options)
      lambda {
        recorder.send "after_rollback", model
      }.should change(RollbackerChange, :count).by(1)

      change_record = RollbackerChange.last
      change_record.action.should           == action.to_s
      change_record.rollbackable_id.should     == model.id
      change_record.rollbackable_type.should   == model.class.to_s
      change_record.user_id.should          == @user.id
      change_record.user_type.should        == @user.class.to_s
      change_record.rollbacked_changes.should  == {'name' => [nil, 'Changed'] }
    end

  end

  describe "on :update" do
    let(:action) { :update }
    let(:model)  { Model.create(name: "Name") }
    it "should create the change record" do
      model.name  = 'Changed'
      model.stub(:_rollbacker_action).and_return(action)
      config      = Rollbacker::Config.new(action)
      # recorder    = Rollbacker::Recorder.new(action, config.options)
      recorder    = Rollbacker::Recorder.new(config.options)
      lambda {
        recorder.send "after_rollback", model
      }.should change(RollbackerChange, :count).by(1)

      change_record = RollbackerChange.last
      change_record.action.should           == action.to_s
      change_record.rollbackable_id.should  == model.id
      change_record.rollbackable_type.should== model.class.to_s
      change_record.user_id.should          == @user.id
      change_record.user_type.should        == @user.class.to_s
      change_record.rollbacked_changes.should  == {'name' => ['Name', 'Changed'] }
    end

    it "should only update rollbacked_changes field if the change record already exist" do
      edit1 = RollbackerChange.create(rollbackable: model, user: @user, action: action, rollbacked_changes: {'name'=>[nil, 'Name']})
      # Update
      model.name  = 'Changed'
      model.stub(:_rollbacker_action).and_return(action)
      config      = Rollbacker::Config.new(action)
      # recorder    = Rollbacker::Recorder.new(action, config.options)
      recorder    = Rollbacker::Recorder.new(config.options)

      lambda {
        recorder.send "after_rollback", model
      }.should_not change(RollbackerChange, :count)

      edit2 = RollbackerChange.last
      edit1.id.should == edit2.id
      edit2.action.should             == action.to_s
      edit2.rollbackable_id.should    == model.id
      edit2.rollbackable_type.should  == model.class.to_s
      edit2.user_id.should            == @user.id
      edit2.user_type.should          == @user.class.to_s
      edit2.rollbacked_changes.should == {'name' => ['Name', 'Changed'] }
    end
  end

  it 'should pass the model, record, user, and action to any supplied block' do
    model     = Model.create
    model.stub(:_rollbacker_action).and_return(:create)
    config    = Rollbacker::Config.new(:create)
    # recorder  = Rollbacker::Recorder.new(:create, config.options) do |model, record, user, action|
    recorder  = Rollbacker::Recorder.new(config.options) do |model, record, user, action|
      model.should  == model
      record.should be_is_a(RollbackerChange)
      user.should   == @user
      action.should == :create
    end
    recorder.after_rollback(model)
  end

end
