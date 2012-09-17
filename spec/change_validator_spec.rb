require File.dirname(__FILE__) + '/spec_helper'
require 'rollbacker/config'

describe Rollbacker::ChangeValidator do
  describe ":destroy" do
    let(:action) { :destroy }
    it "should not be valid if the model is a new record" do
      model     = Model.new
      config    = Rollbacker::Config.new(action)
      validator = Rollbacker::ChangeValidator.new(action, config.options, model)
      model.should be_new_record
      validator.changes.should == {}
      validator.should_not be_valid
    end
    it "should be valid if the model is persisted" do
      model     = Model.create
      config    = Rollbacker::Config.new(action)
      validator = Rollbacker::ChangeValidator.new(action, config.options, model)
      model.should be_persisted
      validator.changes.should == {}
      validator.should be_valid
    end
  end

  [:create, :update].each do |action|
    describe ":#{ action }" do
      it "should be invalid if model has no change" do
        model     = Model.new
        config    = Rollbacker::Config.new(action)
        validator = Rollbacker::ChangeValidator.new(action, config.options, model)
        validator.changes.should == {}
        validator.should_not be_valid
      end
      it "should be valid if model changed" do
        model     = Model.new(name: "Name")
        config    = Rollbacker::Config.new(action)
        validator = Rollbacker::ChangeValidator.new(action, config.options, model)
        model.should be_changed
        validator.changes.should == {'name' => [nil, 'Name']}
        validator.should be_valid
      end
      it "should ignore fields from :except config" do
        model     = Model.new(name: "Name", value: "Value")
        config    = Rollbacker::Config.new(action, :except => :name)
        validator = Rollbacker::ChangeValidator.new(action, config.options, model)
        model.should be_changed
        model.changes.keys.should be_include('name')
        model.changes.keys.should be_include('value')
        validator.changes.should == {'value' => [nil, 'Value']}
      end
      it "should select changes from :only config" do
        model     = Model.new(name: "Name", value: "Value")
        config    = Rollbacker::Config.new(action, :only => :value)
        validator = Rollbacker::ChangeValidator.new(action, config.options, model)
        model.should be_changed
        model.changes.keys.should be_include('name')
        model.changes.keys.should be_include('value')
        validator.changes.should == {'value' => [nil, 'Value']}
      end
      it "should be able to merge changes from current rollbacker_change record" do
        model     = Model.new(name: "Newer")
        config    = Rollbacker::Config.new(action)
        validator = Rollbacker::ChangeValidator.new(action, config.options, model)
        model.should be_changed
        model.changes.keys.should be_include('name')
        model.changes.keys.should_not be_include('value')
        validator.changes({
          'value' => [nil, 'Old Value'],
          'name'  => [nil, 'Old Name']
        }).should == {'name' => [nil, 'Newer'], 'value'=> [nil, 'Old Value']}
      end
    end
  end
end
