Rollbacker
==========

**Rollbacker** is a manage tool for auditing changes to your ActiveRecord.
The changes of objects are added to a queue where the auditor can approve and reject those changes.

## Installation

To use it with your Rails 3 project, add the following line to your Gemfile

```ruby
gem 'rollbacker'
```

Generate the migration and create the rollbacker_changes table
```bash
$ rails generate rollbacker:migration
$ rake db:migrate
```

## Usage

Simply call `rollbacker` on your models:

```ruby
class Model < ActiveRecord::Base
  rollbacker(:create, :update, :destroy)
end
```

After that, whenever a model is created, updated or destroyed, a new RollbackerChange record is created.

```ruby
# Create Model
> Model.count
=> 0
> Model.create(name: 'Name', value: 'Value')
=> #<Model id: nil, name: "Name", value: "Value">
> Model.count
=> 0
> RollbackerChange.last.approve
> Model.count
=> 1

# Update Model
> m = Model.first
=> #<Model id: 1, name: "Name", value: "Value">
> m.update_attribute(:name, 'New')
> m.reload
=> #<Model id: 1, name: "Name", value: "Value">
> m.rollbacker_changes.last.rollbacked_changes
=> {"name"=>["Name", "New"]}
> m.update_attributes(:name=>'Newer', :value => 'New')
> m.rollbacker_changes.last.rollbacked_changes
=> {"name"=>["Name", "Newer"], "value"=>["Value", "New"]}
> m.rollbacker_changes.last.approve('value')
> m.reload
=> #<Model id: 1, name: "Name", value: "New">
> m.rollbacker_changes.last.rollbacked_changes
=> {"name"=>["Name", "Newer"]}
> m.rollbacker_changes.last.reject
> m.reload
=> #<Model id: 1, name: "Name", value: "New">

# Destroy Model
> m.destroy
> Model.count
=> 1
> m.rollbacker_changes.last.approve
> Model.count
=> 0
```

The rollbacked_changes column automatically serializes the changes of any model attributes modified during the action. If there are only a few attributes you want to track or a couple that you want to prevent from being tracked, you can specify that in the rollbacker call. For example
```ruby
rollbacker(:create, :destroy, :except => [:title])
rollbacker(:update, :only => :title)
```

### Current User Tracking

If you're using Rollbacker in a Rails application, all changes made within a request will automatically be attributed to the current user. By default, Rollbacker uses the `current_user` method in your controller.

```ruby
class PostsController < ApplicationController
  def create
    current_user # => #<User name: "Steve">
    @post = Post.create(params[:post])
    @post.rollbacker_changes.last.user # => #<User name: "Steve">
  end
end
```

### Integration
There may be some instances where you need to perform an action on your model object without Rollbacker. In those cases you can include the Rollbacker::Status module for help.
```ruby
class PostsController < ApplicationController
  include Rollbacker::Status

  def update
    post = Post.find(params[:id])
    without_rollbacker { post.update_attributes(params[:post]) } # Rollbacker is disabled for the entire block
  end
end
```

You can also force Rollbacker to track any actions within a block as a specified user.
```ruby
class PostsController < ApplicationController
  include Rollbacker::Status

  def update
    post = Post.find(params[:id])
    rollbacker_as(another_user) { post.update_attributes(params[:post]) }
  end
end
```

For more details, I suggest you check out the test examples in the spec folder itself.


