require File.dirname(__FILE__) + '/spec_helper'
require 'rollbacker/user'
require 'rollbacker/status'

describe Rollbacker::DatabaseRollback do
  include Rollbacker::Status

  before(:each) do
    Thread.current[:rollbacker_disabled] = nil
    @user = Rollbacker::User.current_user = User.create
  end

  [:create, :update, :destroy].each do |action|
    it "should respond with around_#{action}" do
      model = Model.new(name: 'name')
      config     = Rollbacker::Config.new(action)
      callback = Rollbacker::DatabaseRollback.new(config.options)
      callback.should respond_to("around_#{action}")
    end
  end

  it "should rollback using without_rollbacker" do
    model = Model.new
    model.should_receive(:"_rollbacker_action=").with(:create).and_return(:create)
    config = Rollbacker::Config.new('create')
    callback = Rollbacker::DatabaseRollback.new(config.options)

    lambda {
      without_rollbacker do
        callback.send :around_create, model
      end
    }.should_not raise_exception(ActiveRecord::Rollback)
  end

  it "should rollback as default with a object with changes" do
    model = Model.new(name: 'name')
    model.should_receive(:"_rollbacker_action=").with(:create).and_return(:create)
    config = Rollbacker::Config.new('create')
    callback = Rollbacker::DatabaseRollback.new(config.options)

    lambda {
      callback.send :around_create, model
    }.should raise_exception(ActiveRecord::Rollback)
  end
end
