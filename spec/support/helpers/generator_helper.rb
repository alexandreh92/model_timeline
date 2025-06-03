# frozen_string_literal: true

require 'generator_spec'

RSpec.configure do |config|
  config.include GeneratorSpec::TestCase, type: :generator
end
