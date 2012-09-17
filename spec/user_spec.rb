require File.dirname(__FILE__) + '/spec_helper'
require 'rollbacker/user'

describe Rollbacker::User do
  it "should return the same user that's set on the same thread" do
    user = "user"
    Rollbacker::User.current_user = user
    Rollbacker::User.current_user.should == user
  end

  it "should not return the same user from a different thread" do
    user = "user"
    user2 = "user2"

    Rollbacker::User.current_user = user

    Thread.new do
      Rollbacker::User.current_user.should be_nil
      Rollbacker::User.current_user = user2
      Rollbacker::User.current_user.should == user2
    end

    Rollbacker::User.current_user.should == user
  end
end
