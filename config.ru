$LOAD_PATH.unshift(File.expand_path '../lib', __FILE__)
require 'rubygems'
require 'db_agent'

run DbAgent::Webapp
