class CreateRollbackerChangesTable < ActiveRecord::Migration
  def self.up
    create_table :rollbacker_changes, :force => true do |t|
      t.column :rollbackable_id, :integer
      t.column :rollbackable_type, :string
      t.column :user_id, :integer
      t.column :user_type, :string
      t.column :action, :string
      t.column :rollbacked_changes, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

    add_index :rollbacker_changes, [:rollbackable_id, :rollbackable_type], :name => 'rollbackable_index'
    add_index :rollbacker_changes, [:user_id, :user_type], :name => 'user_index'
    add_index :rollbacker_changes, :created_at
  end

  def self.down
    drop_table :rollbacker_changes
  end
end
