# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :model_timeline_timeline_entries do |t|
    t.string :timelineable_type
    t.bigint :timelineable_id
    t.string :action, null: false

    t.jsonb :object_changes, default: {}, null: false

    t.string :user_type
    t.bigint :user_id
    t.string :username

    t.inet :ip_address

    t.timestamps
  end

  add_index :model_timeline_timeline_entries, %i[timelineable_type timelineable_id],
            name: 'idx_timeline_on_timelineable'
  add_index :model_timeline_timeline_entries, %i[user_type user_id], name: 'idx_timeline_on_user'
  add_index :model_timeline_timeline_entries, :object_changes, using: :gin, name: 'idx_timeline_on_changes'
  add_index :model_timeline_timeline_entries, :ip_address, name: 'idx_timeline_on_ip'

  # Custom Table
  create_table :custom_timeline_entries do |t|
    t.string :timelineable_type
    t.bigint :timelineable_id
    t.string :action, null: false

    t.jsonb :object_changes, default: {}, null: false

    t.string :user_type
    t.bigint :user_id
    t.string :username

    t.inet :ip_address

    t.timestamps
  end

  add_index :custom_timeline_entries, %i[timelineable_type timelineable_id],
            name: 'idx_custom_timeline_on_timelineable'
  add_index :custom_timeline_entries, %i[user_type user_id], name: 'idx_custom_timeline_on_user'
  add_index :custom_timeline_entries, :object_changes, using: :gin, name: 'idx_custom_timeline_on_changes'
  add_index :custom_timeline_entries, :ip_address, name: 'idx_custom_timeline_on_ip'

  create_table :users, force: true do |t|
    t.string :username
    t.string :email
    t.string :password_digest

    t.timestamps
  end

  create_table :posts, force: true do |t|
    t.string :title
    t.text :content
    t.references :user, foreign_key: true

    t.timestamps
  end
end
