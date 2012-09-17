module Rollbacker
  module User

    def current_user
      Thread.current[:rollbacker_user]
    end

    def current_user=(user)
      Thread.current[:rollbacker_user] = user
    end

    module_function :current_user, :current_user=

  end
end
