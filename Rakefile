require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/*_spec.rb'
end

RSpec::Core::RakeTask.new(:gridium) do |t|
  t.pattern = 'spec/gridium_spec.rb'
end

task :default => :spec
