# frozen_string_literal: true

require 'rake'
require 'rake/testtask'

namespace :audit_logger do
  desc 'Run all tests'
  task :test do
    Rake::TestTask.new do |t|
      t.libs << 'test'
      t.pattern = 'spec/**/*_spec.rb'
    end
    Rake::Task[:test].invoke
  end

  desc 'Generate documentation'
  task :docs do
    sh 'yardoc'
  end
end

task default: 'audit_logger:test'
