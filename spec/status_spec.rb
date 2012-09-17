require File.dirname(__FILE__) + '/spec_helper'
require 'rollbacker/status'

describe Rollbacker::Status do
  it "should be enabled if set to enabled" do
    obj = Class.new { include Rollbacker::Status }.new
    obj.enable_rollbacker!
    obj.should be_rollbacker_enabled
    obj.should_not be_rollbacker_disabled
  end

  it "should be disabled if set to disabled" do
    obj = Class.new { include Rollbacker::Status }.new
    obj.disable_rollbacker!
    obj.should_not be_rollbacker_enabled
    obj.should be_rollbacker_disabled
  end

  it "should allow auditing as a specified user for a block of code" do
    obj = Class.new { include Rollbacker::Status }.new
    user1 = "user1"
    user2 = "user2"
    Rollbacker::User.current_user = user1

    obj.rollbacker_as(user2) { Rollbacker::User.current_user.should == user2 }
    Rollbacker::User.current_user.should == user1
  end

  it "should allow a block of code to be executed with rollbacker disabled" do
    obj = Class.new { include Rollbacker::Status }.new
    obj.enable_rollbacker!
    obj.should be_rollbacker_enabled
    obj.without_rollbacker { obj.should be_rollbacker_disabled }
    obj.should be_rollbacker_enabled
  end

  it "should allow a block of code to be executed with rollbacker enabled" do
    obj = Class.new { include Rollbacker::Status }.new
    obj.disable_rollbacker!
    obj.should be_rollbacker_disabled
    obj.with_rollbacker { obj.should be_rollbacker_enabled }
    obj.should be_rollbacker_disabled
  end
end
