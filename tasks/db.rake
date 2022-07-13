namespace :db do

  task :require do
    $:.unshift File.expand_path('../../lib', __FILE__)
    require 'db_agent'
    include DbAgent
  end

  def db_handler
    @db_handler ||= DbAgent.default_handler
  end

  desc "Pings the database, making sure everything's ready for migration"
  task :ping => :require do
    db_handler.ping
  end

  desc "Drops the user & database (USE WITH CARE)"
  task :drop => :require do
    db_handler.drop
  end

  desc "Creates an fresh new user & database (USE WITH CARE)"
  task :create => :require do
    db_handler.create
  end

  desc "Waits for the database server to ping, up to 15 seconds"
  task :wait_server => :require do
    db_handler.wait_server
  end

  desc "Waits for the database to ping, up to 15 seconds"
  task :wait => :require do
    db_handler.wait
  end

  desc "Dump a database backup"
  task :backup => :require do
    db_handler.backup
  end

  desc "Restore from the last database backup"
  task :restore, :pattern do |t,args|
    db_handler.restore(t, args)
  end
  task :restore => :require

  desc "Runs migrations on the current database"
  task :migrate, [:version] => :require do |_,args|
    version = args[:version].to_i if args[:version]
    db_handler.migrate(version)
  end

  desc "Opens a database REPL"
  task :repl => :require do
    db_handler.repl
  end

  desc "Dumps the schema documentation into database/schema"
  task :spy => :require do
    db_handler.spy
  end

  desc "Rebuilds the database from scratch (USE WITH CARE)"
  task :rebuild => [ :drop, :create, :migrate ]

  desc "Revive the database from the last backup"
  task :revive => [ :restore, :migrate ]


  desc "Checks that all seeds can be installed correctly"
  task :"check-seeds" do
    Seeder.new(db_handler).each_seed(true)
  end
  task :"check-seeds" => :require

  desc "Seeds the database with a particular data set"
  task :seed, :from do |t,args|
    Seeder.new(db_handler).install(args[:from] || 'empty')
  end
  task :seed => :require

  desc "Flushes the database as a particular data set"
  task :flush, :to, :options do |t,args|
    name = args[:to] || Time.now.strftime("%Y%m%d%H%M%S").to_s
    options = instance_eval "{#{args[:options] || ''}}"
    Seeder.new(db_handler).flush(name, **options)
  end
  task :flush => :require

  desc "Flushes the initial empty files as a data set"
  task :flush_empty, :to do |t,args|
    name = args[:to] || Time.now.strftime("%Y%m%d%H%M%S").to_s
    options = args[:options]
    Seeder.new(db_handler).flush_empty(name, options)
  end
  task :flush_empty => :require

  desc "Flushes the database as a particular data set in a .zip file"
  task :zip, :to, :options do |t,args|
    name = args[:to] || Time.now.strftime("%Y%m%d%H%M%S").to_s
    options = instance_eval "{#{args[:options] || ''}}"
    options = options.merge(zip: true)
    Seeder.new(db_handler).flush(name, **options)
  end
  task :zip => :require

  desc "Shows what tables depend on a given one"
  task :dependencies, :of do |t,args|
    puts TableOrderer.new(db_handler).dependencies(args[:of].to_sym).reverse
  end
  task :dependencies => :require

  desc "Shows all tables in order"
  task :tables do |t|
    puts TableOrderer.new(db_handler).tsort
  end
  task :tables => :require

end
