namespace :db do

  task :require do
    $:.unshift File.expand_path('../../lib', __FILE__)
    require 'db_agent'
    include DbAgent
  end

  def db_handler
    @db_handler ||= DbHandler.new
  end

  desc "Pings the database, making sure everything's ready for migration"
  task :ping => :require do
    puts "Using #{DATABASE_CONFIG}"
    SEQUEL_DATABASE.test_connection
    puts "Everything seems fine!"
  end

  desc "Waits for the database server to ping, up to 15 seconds"
  task :wait_server => :require do
    require 'net/ping'
    raise "No host found" unless DATABASE_CONFIG[:host]
    check = Net::Ping::External.new(DATABASE_CONFIG[:host])
    puts "Trying to ping `#{DATABASE_CONFIG[:host]}`"
    15.downto(0) do |i|
      print "."
      if check.ping?
        print "\nServer found.\n"
        break
      elsif i == 0
        print "\n"
        raise "Server not found, I give up."
      else
        sleep(1)
      end
    end
  end

  desc "Waits for the database to ping, up to 15 seconds"
  task :wait => :require do
    15.downto(0) do |i|
      begin
        puts "Using #{DATABASE_CONFIG}"
        SEQUEL_DATABASE.test_connection
        puts "Database is there. Great."
        break
      rescue Sequel::Error
        raise if i==0
        sleep(1)
      end
    end
  end

  desc "Drops the user & database (USE WITH CARE)"
  task :drop => :require do
    DbTasks.drop(DATABASE_CONFIG[:adapter])
  end

  desc "Creates an fresh new user & database (USE WITH CARE)"
  task :create => :require do
    puts "OK I'm here"
  end

  desc "Dump a database backup"
  task :backup => :require do
    datetime = Time.now.strftime("%Y%m%dT%H%M%S")
    shell pg_cmd("pg_dump", "--clean", "> #{BACKUP_FOLDER}/backup-#{datetime}.sql")
  end

  desc "Restore from the last database backup"
  task :restore, :pattern do |t,args|
    candidates = BACKUP_FOLDER.glob("*.sql").sort
    if args[:pattern] && rx = Regexp.new(args[:pattern])
      candidates = candidates.select{|f| f.basename.to_s =~ rx }
    end
    file = candidates.last
    shell pg_cmd('psql', DATABASE_CONFIG[:database], '<', file.to_s)
  end
  task :restore => :require

  desc "Rebuilds the database from scratch (USE WITH CARE)"
  task :rebuild => [ :drop, :create, :migrate ]

  desc "Revive the database from the last backup"
  task :revive => [ :restore, :migrate ]

  desc "Runs migrations on the current database"
  task :migrate => :require do
    Sequel.extension :migration
    if (sf = MIGRATIONS_FOLDER/'superuser').exists?
      Sequel::Migrator.run(SUPERUSER_DATABASE, MIGRATIONS_FOLDER/'superuser', table: 'superuser_migrations')
    end
    Sequel::Migrator.run(SEQUEL_DATABASE, MIGRATIONS_FOLDER)
  end

  desc "Dumps the schema documentation into database/schema"
  task :spy => :require do
    jdbc_jar = (Path.dir.parent/'vendor').glob('postgresql*.jar').first
    system %Q{java -jar vendor/schemaSpy_5.0.0.jar -dp #{jdbc_jar} -t pgsql -host #{DATABASE_CONFIG[:host]} -u #{DATABASE_CONFIG[:user]} -db #{DATABASE_CONFIG[:database]} -s public -o #{SCHEMA_FOLDER}/spy}
    system %Q{open #{SCHEMA_FOLDER}/spy/index.html}
  end

  desc "Opens a database REPL"
  task :repl => :require do
    shell pg_cmd('psql', DATABASE_CONFIG[:database])
  end

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
