# ModelTimeline

ModelTimeline is a flexible audit logging gem for Rails applications that allows you to track changes to your models with comprehensive attribution and flexible configuration options.

## How this gem is different than paper_trail and audited?

ModelTimeline was designed with several unique features that differentiate it from other auditing gems:

- *Multiple configurations per model:* Unlike paper_trail and audited, ModelTimeline allows you to define multiple timeline configurations on the same model. This means you can track different sets of attributes for different purposes.
- *Targeted tracking:* Configure separate timelines for different aspects of your model (e.g., one for security events, another for content changes).
- PostgreSQL optimization: Built to leverage PostgreSQL's JSONB capabilities for efficient storage and advanced querying.
- *IP address tracking:* Automatically captures the client IP address for each change.
- *Rich metadata support:* Add custom metadata to timeline entries via configuration or at runtime.
- *Flexible user attribution:* Works with any authentication system by using a configurable method to retrieve the current user.
- *Comprehensive RSpec support:* Built-in matchers for testing timeline recording.


## Installation

Add this line to your application's Gemfile:

```sh
gem 'model_timeline'
```

And then execute:

```sh
$ bundle install
```

Or install it yourself as:

```sh
$ gem install model_timeline
```

Run the generator to create the necessary migration:

```sh
$ rails generate model_timeline:install
$ rails db:migrate
```

For a custom table name:

```sh
$ rails generate model_timeline:install --table_name=custom_timeline_entries
$ rails db:migrate
```
## Configuration

### Initializer

Configure the gem in an initializer:

```ruby
# config/initializers/model_timeline.rb
ModelTimeline.configure do |config|
  # Method to retrieve the current user in controllers (default: :current_user)
  config.current_user_method = :current_user

  # Method to retrieve the client IP address in controllers (default: :remote_ip)
  config.current_ip_method = :remote_ip

  # Enable/disable timeline tracking globally
  # config.enabled = true # Enabled by default
end
```

### Model Configuration
Include the Timelineable module in your models (this happens automatically with Rails):

> **Important**: When defining multiple timelines on the same model, each must use a unique `class_name` option. Otherwise, the associations will conflict and an error will be raised.

```ruby
# Basic usage with default settings
class User < ApplicationRecord
  has_timeline
end

# Using a custom association name with class_name along default
class User < ApplicationRecord
  has_timeline

  has_timeline :security_events, class_name: 'SecurityTimelineEntry'
end

# Tracking only specific attributes
class User < ApplicationRecord
  has_timeline only: [:last_login_at, :login_count, :status],
               class_name: 'LoginTimelineEntry'
end

# Ignoring specific attributes
class User < ApplicationRecord
  has_timeline :profile_changes,
               ignore: [:password, :remember_token, :login_count],
               class_name: 'ProfileTimelineEntry'
end

# Tracking only specific events
class User < ApplicationRecord
  has_timeline :content_changes,
               on: [:update, :destroy],
               class_name: 'ContentTimelineEntry'
end

# Using a custom timeline entry class and table
class User < ApplicationRecord
  has_timeline :custom_timeline_entries,
               class_name: 'CustomTimelineEntry'
end

# Adding additional metadata to each entry
class Order < ApplicationRecord
  has_timeline :admin_changes,
               class_name: 'AdminTimelineEntry',
               meta: {
                 app_version: "1.0",
                 # Dynamic values using methods or procs
                 section: :section_name,
                 category_id: ->(record) { record.category_id }
               }
end
```

### Using Metadata

ModelTimeline allows you to include custom metadata with your timeline entries, which is especially useful for tracking changes across related entities or adding domain-specific context.

#### Adding Metadata Through Configuration

When defining a timeline, any fields you include in the `meta` option will be evaluated and stored in the timeline entry:

```ruby
class Comment < ApplicationRecord
  belongs_to :post

  has_timeline :comment_changes,
               class_name: 'ContentTimelineEntry',
               meta: {
                 post_id: ->(record) { record.post_id },
               }
end
```

If your timeline table has columns that match the keys in your `meta` hash, these values will be stored in
those dedicated columns. Otherwise, they will be stored inside `metadata` column.

#### Adding Metadata at Runtime

```ruby
# Add metadata for a specific operation
ModelTimeline.with_metadata(post_id: '123456') do
  comment.update(body: 'Updated comment')
end

# Add metadata for the current thread/request
ModelTimeline.metadata = { post_id: '123456' }
comment.update(status: 'approved')
```

#### Custom Timeline Tables with Domain-specific Columns

For tracking related entities more effectively, you can create a custom timeline table with additional columns:

```ruby
# Migration to create a product-specific timeline table
class CreatePostTimelineEntries < ActiveRecord::Migration[6.1]
  def change
    create_table :post_timeline_entries do |t|
      # Default Columns - All of them are required.
      t.string :timelineable_type
      t.bigint :timelineable_id
      t.string :action, null: false
      t.jsonb :object_changes, default: {}, null: false
      t.jsonb :metadata, default: {}, null: false
      t.string :user_type
      t.bigint :user_id
      t.string :username
      t.inet :ip_address

      # Custom columns that can be populated via the meta option
      t.integer  :post_id

      t.timestamps
    end

    add_index :post_timeline_entries, [:timelineable_type, :timelineable_id], name: 'idx_timeline_on_timelineable'
    add_index :post_timeline_entries, [:user_type, :user_id], name: 'idx_timeline_on_user'
    add_index :post_timeline_entries, :object_changes, using: :gin, name: 'idx_timeline_on_changes'
    add_index :post_timeline_entries, :metadata, using: :gin, name: 'idx_timeline_on_meta'
    add_index :post_timeline_entries, :ip_address, name: 'idx_timeline_on_ip'
    add_index :post_timeline_entries, :post_id, name: 'idx_timeline_on_post_id'
  end
end
```

Then, use this table with your models:

```ruby
class Comment < ApplicationRecord
  belongs_to :post

  has_timeline :product_changes,
               class_name: 'PostTimelineEntry',
               meta: {
                 post_id: ->(record) { record.post_id },
                 #  OR
                 # post_id: :post_id
                 #  OR
                 # post_id: :my_custom_post_id_method
               }
end
```

With this approach, you can easily query all changes related to a specific post or product:

```ruby
# Find all timeline entries for a specific post
PostTimelineEntry.where(post_id: post.id)
```

This makes it significantly easier to track and analyze changes across related models within a specific domain context.

### Controller Integration

Define the current user and ip_address for the current request

```ruby
class ApplicationController < ActionController::Base
  private

    # ModelTimeline will look for the methods set in the initializer.
    # Given
    #  ModelTimeline.configure do |config|
    #   config.current_user_method = :my_current_user
    #   config.current_ip_method = :remote_ip
    # end
    #
    def my_current_user
      my_current_user_instance
    end

    def remote_ip
      request.remote_ip
    end
end
```

## Usage

### Basic Usage

Once configured, ModelTimeline automatically tracks changes to your models:

```ruby
user = User.create(username: 'johndoe', email: 'john@example.com')
# Creates a timeline entry with action: 'create'

user.update(email: 'new@example.com')
# Creates a timeline entry with action: 'update' and the changed attributes

user.destroy
# Creates a timeline entry with action: 'destroy'
```

### Accessing Timeline Entries


```ruby
# Get all timeline entries for a model
user.timeline_entries

# Get timeline entries with a specific action
user.timeline_entries.where(action: 'update')

# Find entries for a specific user
ModelTimeline::TimelineEntry.for_user(admin)

# Find entries from a specific IP
ModelTimeline::TimelineEntry.for_ip_address('192.168.1.1')
```

### Custom Tables and Models

```ruby
# Create a custom timeline entry class
class SecurityTimelineEntry < ModelTimeline::TimelineEntry
  self.table_name = 'security_timeline_entries'

  # Add custom scopes or methods
  scope :critical, -> { where("object_changes::text ILIKE '%password%'") }
end

# Use it in your model
class User < ApplicationRecord
  has_timeline :security_timelines,
               class_name: 'SecurityTimelineEntry',
               only: [:sign_in_count, :last_sign_in_at, :role]
end

# Access the custom timeline
user.security_timelines
```

### Controlling Timeline Recording

Temporarily enable or disable timeline recording:

```ruby
# Disable timeline recording for a block of code
ModelTimeline.without_timeline do
  # Changes made here won't be recorded
  user.update(name: 'New Name')
  post.destroy
end

# Set custom context for timeline entries
ModelTimeline.with_timeline(current_user: admin_user, current_ip: '10.0.0.1', metadata: { reason: 'Admin action' }) do
  # Changes made here will be attributed to admin_user from 10.0.0.1
  # with the additional metadata
  user.update(status: 'suspended')
end
```

Add additional contextual information to timeline entries:

```ruby
# Set metadata for all timeline entries in the current request
ModelTimeline.metadata = { import_batch: 'daily_sync_2023_01_01' }

# Temporarily add or override metadata for a block
ModelTimeline.with_metadata(source: 'api') do
  # All timeline entries created here will include this metadata
  user.update(status: 'active')
end
```

### Timeline Entry Scopes

ModelTimeline provides several useful scopes for querying timeline entries:

```ruby
# Find entries for a specific model
ModelTimeline::TimelineEntry.for_timelineable(user)

# Find entries created by a specific user
ModelTimeline::TimelineEntry.for_user(admin)

# Find entries from a specific IP address
ModelTimeline::TimelineEntry.for_ip_address('192.168.1.1')

# Find entries where a specific attribute was changed
ModelTimeline::TimelineEntry.with_changed_attribute('email')

# Find entries where an attribute was changed to a specific value
ModelTimeline::TimelineEntry.with_changed_value('status', 'active')
```

### PostgreSQL-Specific Features

ModelTimeline leverages PostgreSQL's JSONB capabilities for efficient querying:

```ruby
# Find timeline entries containing specific changes using JSONB containment
TimelineEntry.where("object_changes @> ?", {email: ["old@example.com", "new@example.com"]}.to_json)

# Search for any value in the changes
TimelineEntry.where("object_changes::text LIKE ?", "%specific_value%")
```

The gem creates GIN indexes on the JSONB columns for optimized performance with large audit logs.


## RSpec Integration

### Configuration

Configure RSpec to work with ModelTimeline:

```ruby
# spec/support/model_timeline.rb
require 'model_timeline/rspec'

RSpec.configure do |config|
  # This disables ModelTimeline by default in tests for better performance
  config.before(:suite) do
    ModelTimeline.disable!
  end

  # Include the RSpec helpers and matchers
  config.include ModelTimeline::RSpec
end
```

#### Enabling Timeline in Tests

ModelTimeline is disabled by default in tests for performance. Enable it selectively:

```ruby
# Enable timeline for a single test with metadata
it 'tracks changes', :with_timeline do
  # ModelTimeline is enabled here
  user = create(:user)
  expect(user.timeline_entries).to exist
end

# Enable timeline for a group of tests
describe 'tracked actions', :with_timeline do
  it 'tracks creation' do
    post = create(:post)
    expect(post.timeline_entries.count).to eq(1)
  end

  it 'tracks updates' do
    post = create(:post)
    post.update(title: 'New Title')
    expect(post.timeline_entries.count).to eq(2)
  end
end

# Tests without the metadata will have timeline disabled
it 'does not track changes' do
  user = create(:user)
  expect(ModelTimeline::TimelineEntry.count).to eq(0)
end
```

#### RSpec Matchers

ModelTimeline provides several matchers for testing timeline entries:

```ruby
# Check for any timeline entries
expect(user).to have_timeline_entries

# Check for a specific number of entries
expect(user).to have_timeline_entries(3)

# Check for entries with a specific action
expect(user).to have_timelined_action(:update)

# Check if a specific attribute was changed
expect(user).to have_timelined_change(:email)

# Check if an attribute was changed to a specific value
expect(user).to have_timelined_entry(:status, 'active')
```

These matchers make it easy to test that your application is correctly tracking model changes.


## License

The gem is available as open source under the terms of the MIT License.
