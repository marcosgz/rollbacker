module TransactionalSpecs

  def self.included(base)
    base.class_eval do
      around(:each) do |spec|
        begin
          spec.call
        ensure
          [User, Model, RollbackerChange].each do |clazz|
            clazz.delete_all
          end
        end
      end
    end
  end

end
