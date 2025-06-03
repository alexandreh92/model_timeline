# frozen_string_literal: true

RSpec.configure do |config|
  # Disable ModelTimeline by default for all tests
  config.before(:suite) do
    ModelTimeline.disable!
  end

  config.include ModelTimeline::RSpec
end
