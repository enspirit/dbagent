require "rspec/core/rake_task"
namespace :test do

  desc "Runs unit tests"
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = "spec/**/test_*.rb"
    t.rspec_opts = ["-Ilib", "-Ispec", "--color", "--backtrace", "--format=progress"]
  end

  task :all => :"unit"
end
task :test => :"test:all"
