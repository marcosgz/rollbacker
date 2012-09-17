require File.dirname(__FILE__) + '/spec_helper'

describe MyModel do
  let(:model) { MyModel.new(name: 'Name', value: 'Value') }

  context "new record" do
    it 'add create callback to history' do
      lambda {
        model.save
      }.should_not change(MyModel, :count)
      model.history.should == ['after_rollback_on_create']
    end
  end

  context "persisted record" do
    before(:each) do
      model.skip_before_create = true
      model.save
    end
    it 'add update callback to history' do
      lambda {
        model.update_attribute(:name, 'Newer')
      }.should_not change(MyModel, :count)
      model.history.should == ['after_rollback_on_update']
    end
    pending 'add destroy callback to history' do
      lambda {
        model.destroy
      }.should_not change(MyModel, :count)
      # Currently the result of this test is:
      # model.history.should == ['after_rollback_on_update']
      # See more details here: https://github.com/rails/rails/issues/7640
      model.history.should == ['after_rollback_on_destroy']
    end
  end
end
