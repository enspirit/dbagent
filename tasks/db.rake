namespace :db do

  task :require do
    $:.unshift File.expand_path('../../lib', __FILE__)
    require 'db_agent'
    include DbAgent
  end

  def db_handler
    @db_handler ||= DbHandler.factor(DATABASE_CONFIG, BACKUP_FOLDER, SCHEMA_FOLDER, SUPERUSER_CONFIG)
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
  task :migrate => :require do
    db_handler.migrate
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
    Seeder.new.each_seed(true)
  end
  task :"check-seeds" => :require

  desc "Seeds the database with a particular data set"
  task :seed, :from do |t,args|
    Seeder.new.install(args[:from] || 'empty')
  end
  task :seed => :require

  desc "Flushes the database as a particular data set"
  task :flush, :to do |t,args|
    Seeder.new.flush(args[:to] || Time.now.strftime("%Y%M%d%H%M%S").to_s)
  end
  task :flush => :require

  desc "Shows what tables depend on a given one"
  task :dependencies, :of do |t,args|
    puts TableOrderer.new.dependencies(args[:of].to_sym).reverse
  end
  task :dependencies => :require

  desc "Shows all tables in order"
  task :tables do |t|
    puts TableOrderer.new.tsort
  end
  task :tables => :require

end
