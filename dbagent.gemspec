$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'db_agent/version'
require 'date'

Gem::Specification.new do |s|
  s.name        = 'dbagent'
  s.version     = DbAgent::VERSION
  s.date        = Date.today.to_s
  s.summary     = "A tool to migrate, spy and seed relational databases."
  s.description = "A tool to migrate, spy and seed relational databases"
  s.authors     = ["Bernard Lambeau"]
  s.email       = 'blambeau@gmail.com'
  s.files       = Dir['LICENSE.md','Gemfile','Rakefile','{lib,tasks}/**/*','README*'] & `git ls-files -z`.split("\0")
  s.homepage    = 'http://github.com/enspirit/dbagent'
  s.license     = 'MIT'

  s.add_dependency 'sequel', "~> 5"
  s.add_dependency 'pg', '~> 1'
  s.add_dependency 'rake', '~> 13'
  s.add_dependency 'path', '~> 2'
  s.add_dependency 'sinatra', '~> 2'
  s.add_dependency 'bmg', '~> 0.20'
  s.add_dependency 'net-ping', "~> 2"
  s.add_dependency "predicate", "~> 2", ">= 2.7.1"
  s.add_dependency 'thin', '~> 1'

  s.add_development_dependency 'bundler', '~> 2'
  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rack-test', '~> 1'
end
