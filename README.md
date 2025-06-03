# ModelTimeline

ModelTimeline is a flexible audit logging gem for Rails applications that allows you to track changes to your models with multiple configurable audit loggers.



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'model_timeline'
```

And then execute:

```
$ bundle install
```

Or install it yourself as:

```
$ gem install model_timeline
```

Run the generator to create the necessary migration:

```
$ rails generate model_timeline:install
$ rails db:migrate
```

## Usage

Configure the gem in an initializer:

```ruby
# config/initializers/model_timeline.rb
ModelTimeline.configure do |config|
  config.current_user_method = :current_user
end
```

### Install

```bash
rails generate model_timeline:install --table_name=custom_timeline_entries
```

Include the Auditable module in your models:

```ruby
class User < ApplicationRecord
  include ModelTimeline::Auditable

  # Basic usage - uses 'default_audit_logs' as table name
  has_audit_logger :default

  # Custom table name
  has_audit_logger :security, table_name: 'security_audit_logs'

  # Track only specific events and fields
  has_audit_logger :login_history,
                   on: [:create, :update],
                   only: [:last_login_at, :login_count]

  # Ignore specific attributes
  has_audit_logger :profile_tracking,
                   ignore: [:password, :remember_token, :login_count]
end
```

Access the logs:

```ruby
user = User.find(1)

# Get all audit logs for a user
logs = ModelTimeline::AuditInstance.for_auditable(user)

```

# PostgreSQL-Specific Features

ModelTimeline takes advantage of PostgreSQL's powerful JSONB capabilities for efficient querying:

## Advanced Querying

```ruby
# Find entries where a specific attribute was changed
TimelineEntry.with_changed_attribute(:email)

# Find entries where an attribute was changed to a specific value
TimelineEntry.with_changed_value(:status, "active")

# Use native PostgreSQL operators for complex queries
TimelineEntry.where("changes @> ?", {email: ["old@example.com", "new@example.com"]}.to_json)

# Find changes to any attribute containing a specific value (using containment)
TimelineEntry.where("changes::text LIKE ?", "%specific_value%")
```

## Performance

ModelTimeline uses GIN indexes on the JSONB changes column, providing efficient querying for large audit logs.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## RSpec

```
require 'model_timeline/rspec'

RSpec.configure do |config|
  config.include ModelTimeline::RSpec

  # Other configuration...
end
```

```
# Timeline is disabled by default in all tests

# Enable timeline for a specific test
it 'tracks changes', :with_timeline do
  # ModelTimeline is enabled here
  user = create(:user)
  expect(ModelTimeline::TimelineEntry.count).to eq(1)
end

# Enable timeline for a group of tests
describe 'tracked actions', :with_timeline do
  it 'tracks creation' do
    # ModelTimeline is enabled here
    post = create(:post)
    expect(post.timeline_entries.count).to eq(1)
  end

  it 'tracks updates' do
    # ModelTimeline is still enabled here
    post = create(:post)
    post.update(title: 'New Title')
    expect(post.timeline_entries.count).to eq(2)
  end
end

# Tests without the metadata will have timeline disabled
it 'does not track changes' do
  # ModelTimeline is disabled here
  user = create(:user)
  expect(ModelTimeline::TimelineEntry.count).to eq(0)
end
```
