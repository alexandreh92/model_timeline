require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'active_record'
require 'pg'
require 'factory_bot'
require 'faker'
require 'database_cleaner/active_record'
require 'pry-byebug'
require 'ostruct'

# Load the gem
require 'model_timeline'


# Include the Timelineable module in ActiveRecord::Base
# This allows all ActiveRecord models to use the timeline functionality
# something that railtie would typically handle
ActiveRecord::Base.include(ModelTimeline::Timelineable)

# Setup test database connection
ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  host: ENV['POSTGRES_HOST'] || 'localhost',
  username: ENV['POSTGRES_USER'] || 'postgres',
  password: ENV['POSTGRES_PASSWORD'] || 'postgres',
  database: 'model_timeline_test'
)

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].
  reject { |f| f.include?('schema.rb') }.
  each { |f| require f }

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # Set up FactoryBot
  FactoryBot.definition_file_paths = [File.expand_path('factories', __dir__)]
  FactoryBot.find_definitions

  # Database cleaner setup
  config.before(:suite) do
    # No need to load schema here as it's now in setup_test_db
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
