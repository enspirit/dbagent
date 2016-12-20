namespace :test do

  desc %q{Run all RSpec tests}
  task :unit do
    require 'rspec'
    RSpec::Core::Runner.run(%w[-I. -Ilib -Ispec --pattern=spec/**/test_*.rb --color .])
  end

  task :all => :"unit"
end
task :test => :"test:all"
