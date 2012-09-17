## Rollbacker ##

Rollbacker is a manage tool for auditing changes to your ActiveRecord.
The changes of objects are added to a queue where the auditor can approve and reject those changes.

## Installation ##

To use it with your Rails 3 project, add the following line to your Gemfile

  gem 'rollbacker'

Generate the migration and create the rollbacker_changes table

  rails generate rollbacker:migration
  rake db:migrate

