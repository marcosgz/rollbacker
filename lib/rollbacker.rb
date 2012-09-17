require 'rollbacker/rollbacker_change'
require 'rollbacker/base'

module Rollbacker
  class Error < StandardError; end
end

ActiveRecord::Base.send :include, Rollbacker::Base

if defined?(ActionController) and defined?(ActionController::Base)

  require 'rollbacker/user'

  ActionController::Base.class_eval do
    before_filter do |c|
      Rollbacker::User.current_user = c.send(:current_user) if c.respond_to?(:current_user)
    end
  end

end

