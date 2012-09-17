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

  describe '#new_attributes' do
    it "should collect all new values" do
      record = RollbackerChange.new(rollbacked_changes: {'name'=>[nil, 'Name'], 'value'=>[nil, 'Value']})
      record.new_attributes.should == {'name'=>'Name','value'=>'Value'}
    end

    it "should select only specific attributes" do
      record = RollbackerChange.new(rollbacked_changes: {'name'=>[nil, 'Name'], 'value'=>[nil, 'Value']})
      record.new_attributes('name').should == {'name'=>'Name'}
      record.new_attributes(:name).should == {'name'=>'Name'}
    end
  end

  describe '#update_changes_after_approve_or_reject' do
    it "should remove edits from rollbacked_changes field" do
      record = RollbackerChange.new(rollbacked_changes: {'name'=>[nil, 'Name'], 'value'=>[nil, 'Value']})
      record.send(:update_changes_after_approve_or_reject, 'name')
      record.rollbacked_changes.should == {'value'=>[nil, 'Value']}
      record.should_not be_destroyed
    end

    it "should be able update multiple fields" do
      record = RollbackerChange.new(rollbacked_changes: {'name'=>[nil, 'Name'], 'value'=>[nil, 'Value']})
      record.send(:update_changes_after_approve_or_reject, 'name', 'value')
      record.rollbacked_changes.should be_nil
      record.should be_destroyed
    end

    it "should destroy record and remove all changes with no arguments" do
      record = RollbackerChange.new(rollbacked_changes: {'name'=>[nil, 'Name'], 'value'=>[nil, 'Value']})
      record.send(:update_changes_after_approve_or_reject)
      record.rollbacked_changes.should be_nil
      record.should be_destroyed
    end

    it "should destroy record if no more changes" do
      record = RollbackerChange.create(rollbacked_changes: {'name'=>[nil, 'Name']})
      record.send(:update_changes_after_approve_or_reject, 'name')
      record.rollbacked_changes.should be_nil
      record.should be_destroyed
    end

    it "should destroy record if no more changes" do
      record = RollbackerChange.create(rollbacked_changes: {'name'=>[nil, 'Name']})
      record.send(:update_changes_after_approve_or_reject, :name)
      record.rollbacked_changes.should be_nil
      record.should be_destroyed
    end
  end

  describe "reject" do
    context "on :update" do
      let(:action) { :update }
      it "should not change anything with a has no change about the field" do
        record = RollbackerChange.create({
          :rollbacked_changes => {'name'=>[nil, 'Name']},
          :rollbackable       => @rollbackable,
          :user               => @user,
          :action             => action
        })
        record.rollbackable.should be_present
        record.should be_update_action
        lambda {
          record.reject('value').should be_true
        }.should_not change(RollbackerChange, :count)
        record.reload.rollbacked_changes.should == {'name'=>[nil, 'Name']}
      end
      it "should NOT apply the change to the auditable model" do
        record = RollbackerChange.create({
          :rollbacked_changes => {'name'=>[nil, 'Name'], 'value'=>[nil, 'Value']},
          :rollbackable       => @rollbackable,
          :user               => @user,
          :action             => action
        })
        record.rollbackable.should be_present
        record.should be_update_action
        lambda {
          record.reject('name').should be_true
        }.should_not change(RollbackerChange, :count)
        @rollbackable.reload.name.should be_nil
        record.rollbacked_changes.should == {'value'=>[nil, 'Value']}
        record.should_not be_destroyed
      end
    end

    context "on :create" do
      let(:action) { :create }
      it "should NOT be created if has no change about the field" do
        record = RollbackerChange.create({
          :rollbacked_changes => {'name'=>[nil, 'Name']},
          :rollbackable_type  => 'Model',
          :user               => @user,
          :action             => action
        })
        record.should be_create_action
        lambda {
          lambda {
            record.reject('value').should be_true
          }.should_not change(RollbackerChange, :count)
        }.should_not change(Model, :count)
        record.reload.rollbacked_changes.should == {'name'=>[nil, 'Name']}
      end
      it "should be able to only update changes without insert a new record" do
        record = RollbackerChange.create({
          :rollbacked_changes => {'name'=>[nil, 'Name'], 'value'=>[nil, 'Value']},
          :rollbackable_type  => 'Model',
          :user               => @user,
          :action             => action
        })
        record.should be_create_action
        lambda {
          lambda {
            record.reject('value').should be_true
          }.should_not change(RollbackerChange, :count)
        }.should_not change(Model, :count)
        record.reload.rollbacked_changes.should == {'name'=>[nil, 'Name']}
      end
    end
    context "on :destroy" do
      let(:action) { :destroy }
      it "should only remove rollbacker_change record and discart rollbacked_changes" do
        record = RollbackerChange.create({
          :rollbacked_changes => {'name'=>[nil, 'Name'], 'value'=>[nil, 'Value']},
          :rollbackable       => @rollbackable,
          :user               => @user,
          :action             => action
        })
        record.rollbackable.should be_present
        record.should be_destroy_action
        lambda {
          lambda {
            record.reject.should be_true
          }.should change(RollbackerChange, :count).by(-1)
        }.should_not change(Model, :count)
        @rollbackable.reload.name.should  be_nil
        @rollbackable.reload.value.should be_nil
        record.rollbacked_changes.should  be_nil
        record.should be_destroyed
      end
    end
  end

  describe "approve" do
    context "on :update" do
      let(:action) { :update}
      it "should not change anything with a has no change about the field" do
        record = RollbackerChange.create({
          :rollbacked_changes => {'name'=>[nil, 'Name']},
          :rollbackable       => @rollbackable,
          :user               => @user,
          :action             => action
        })
        record.rollbackable.should be_present
        record.should be_update_action
        lambda {
          lambda {
            record.approve('value').should be_nil
          }.should_not change(RollbackerChange, :count)
        }.should_not change(Model, :count)
        record.reload.rollbacked_changes.should == {'name'=>[nil, 'Name']}
      end
      it "should apply the change to the auditable model from a specific field" do
        record = RollbackerChange.create({
          :rollbacked_changes => {'name'=>[nil, 'Name'], 'value'=>[nil, 'Value']},
          :rollbackable       => @rollbackable,
          :user               => @user,
          :action             => action
        })
        record.rollbackable.should be_present
        record.should be_update_action
        lambda {
          lambda {
            record.approve('name').should be_true
          }.should_not change(RollbackerChange, :count)
        }.should_not change(Model, :count)
        @rollbackable.reload.name.should == 'Name'
        record.reload.rollbacked_changes.should == {'value'=>[nil, 'Value']}
        record.should_not be_destroyed
      end
      it "should apply all changes to the auditable model" do
        record = RollbackerChange.create({
          :rollbacked_changes => {'name'=>[nil, 'Name'], 'value'=>[nil, 'Value']},
          :rollbackable       => @rollbackable,
          :user               => @user,
          :action             => action
        })
        record.rollbackable.should be_present
        record.should be_update_action
        lambda {
          lambda {
            record.approve.should be_true
          }.should change(RollbackerChange, :count).by(-1)
        }.should_not change(Model, :count)
        @rollbackable.reload.name.should == 'Name'
        @rollbackable.reload.value.should == 'Value'
        record.rollbacked_changes.should be_nil
        record.should be_destroyed
      end
    end

    context "on :create" do
      let(:action) { :create }
      it "should not change anything with a has no change about the field" do
        record = RollbackerChange.create({
          :rollbacked_changes => {'name'=>[nil, 'Name']},
          :rollbackable_type  => 'Model',
          :user               => @user,
          :action             => action
        })
        record.should be_create_action
        lambda {
          lambda {
            record.approve('value').should be_nil
          }.should_not change(RollbackerChange, :count)
        }.should_not change(Model, :count)
        record.reload.rollbacked_changes.should == {'name'=>[nil, 'Name']}
      end
      it "should be created a rollbackable model from specific fields" do
        record = RollbackerChange.create({
          :rollbacked_changes => {'name'=>[nil, 'Newer Name'], 'value'=>[nil,'Newer Value']},
          :rollbackable_type  => 'Model',
          :user               => @user,
          :action             => action
        })
        record.should be_create_action
        lambda {
          lambda {
            record.approve('name').should be_true
          }.should change(RollbackerChange, :count).by(-1)
        }.should change(Model, :count).by(1)
        record.rollbacked_changes.should be_nil
        record.should be_destroyed
        rollbackable = Model.last
        rollbackable.name.should == 'Newer Name'
        rollbackable.value.should be_nil
      end
      it "should be created a rollbackable model with all fields" do
        record = RollbackerChange.create({
          :rollbacked_changes => {'name'=>[nil, 'Name'], 'value'=>[nil,'Value']},
          :rollbackable_type  => 'Model',
          :user               => @user,
          :action             => action
        })
        record.should be_create_action
        lambda {
          lambda {
            record.approve.should be_true
          }.should change(RollbackerChange, :count).by(-1)
        }.should change(Model, :count).by(1)
        record.rollbacked_changes.should be_nil
        record.should be_destroyed
        rollbackable = Model.last
        rollbackable.name.should == 'Name'
        rollbackable.value.should == 'Value'
      end
    end
    context "on :destroy" do
      let(:action) { :destroy }
      it "should not change anything with a has no change about the field" do
        record = RollbackerChange.create({
          :rollbacked_changes => nil,
          :rollbackable       => @rollbackable,
          :user               => @user,
          :action             => action
        })
        record.rollbackable.should be_present
        record.should be_destroy_action
        lambda {
          lambda {
            record.approve.should be_true
          }.should change(RollbackerChange, :count).by(-1)
        }.should change(Model, :count).by(-1)
        record.rollbacked_changes.should == nil
        record.should be_destroyed
        @rollbackable.should be_destroyed
      end
    end
  end
end

