require File.dirname(__FILE__) + '/spec_helper'
require 'rollbacker/config'

describe Rollbacker::Config do

  describe 'Configuration' do
    it "should parse actions and options from a config array" do
      config = Rollbacker::Config.new(:create, 'update', {:only => :username})
      config.actions.should_not be_nil
      config.options.should_not be_nil
      config.actions.should have(2).items
      config.actions.should =~ [:create, :update]
      config.options.should == {:only => ["username"], :except => []}
    end

    it "should parse actions and options from a config array when options are absent" do
      config = Rollbacker::Config.new(:create, 'update')
      config.actions.should_not be_nil
      config.actions.should have(2).items
      config.actions.should =~ [:create, :update]
      config.options.should == {:only => [], :except => []}
    end

    it "should parse actions" do
      config = Rollbacker::Config.new(:create)
      config.actions.should_not be_nil
      config.actions.should have(1).item
      config.actions.should =~ [:create]
      config.options.should == {:only => [], :except => []}
    end
  end

  describe 'Configuration Validation' do
    it "should raise a Rollbacker::Error if no action is specified" do
      lambda {
        Rollbacker::Config.new
      }.should raise_error(Rollbacker::Error)
    end

    it "should raise a Rollbacker::Error if an invalid action is specified" do
      lambda {
        Rollbacker::Config.new(:create, :view)
      }.should raise_error(Rollbacker::Error)
    end

  end

end
