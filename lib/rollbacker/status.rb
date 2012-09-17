require 'rollbacker/user'

module Rollbacker
  module Status

    def rollbacker_disabled?
      Thread.current[:rollbacker_disabled] == true
    end

    def rollbacker_enabled?
      Thread.current[:rollbacker_disabled].nil? || Thread.current[:rollbacker_disabled] == false
    end

    def disable_rollbacker!
      Thread.current[:rollbacker_disabled] = true
    end

    def enable_rollbacker!
      Thread.current[:rollbacker_disabled] = false
    end

    def without_rollbacker
      previously_disabled = rollbacker_disabled?

      begin
        disable_rollbacker!
        result = yield if block_given?
      ensure
        enable_rollbacker! unless previously_disabled
      end

      result
    end

    def with_rollbacker
      previously_disabled = rollbacker_disabled?

      begin
        enable_rollbacker!
        result = yield if block_given?
      ensure
        disable_rollbacker! if previously_disabled
      end

      result
    end

    def rollbacker_as(user)
      previous_user = Rollbacker::User.current_user

      begin
        Rollbacker::User.current_user = user
        result = yield if block_given?
      ensure
        Rollbacker::User.current_user = previous_user
      end

      result
    end

  end
end
