module Rollbacker
  class ChangeValidator
    attr_reader :action
    attr_reader :options

    def initialize(action, options, model)
      @action   = action
      @options  = options
      @model    = model
    end

    def valid?
      case @action
      when :destroy
        @model.persisted?
      when :update, :create
        self.changes.any?
      end
    end

    def changes(other_changes={})
      chg = @model.changes.dup
      chg.reverse_merge!( (other_changes || {}).with_indifferent_access )
      chg.reject!{|key, value| @options[:except].include?(key) } unless @options[:except].blank?
      chg.reject!{|key, value| !@options[:only].include?(key)  } unless @options[:only].blank?
      chg
    end

  end
end
