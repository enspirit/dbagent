namespace :db do

  task :require do
    $:.unshift File.expand_path('../../lib', __FILE__)
    require 'db_agent'
    include DbAgent
  end

  def pg_cmd(cmd, *args)
    conf = DATABASE_CONFIG
    %Q{#{cmd} -h #{conf[:host]} -p #{conf[:port]} -U #{conf[:user]} #{args.join(' ')}}
  end

  def psql(*args)
    pg_cmd('psql', *args)
  end

  def shell(*cmds)
    cmd = cmds.join("\n")
    puts cmd
    system cmd
  end

  desc "Pings the database, making sure everything's ready for migration"
  task :ping => :require do
    puts "Using #{DATABASE_CONFIG}"
    SEQUEL_DATABASE.test_connection
    puts "Everything seems fine!"
  end

  desc "Drops the user & database (USE WITH CARE)"
  task :drop => :require do
    shell pg_cmd("dropdb", DATABASE_CONFIG[:database]),
          pg_cmd("dropuser", DATABASE_CONFIG[:user])
  end

  desc "Creates an fresh new user & database (USE WITH CARE)"
  task :create => :require do
    shell pg_cmd("createuser","--no-createdb","--no-createrole","--no-superuser","--no-password",DATABASE_CONFIG[:user]),
          pg_cmd("createdb","--owner=#{DATABASE_CONFIG[:user]}", DATABASE_CONFIG[:database])
  end

  desc "Rebuilds the database from scratch (USE WITH CARE)"
  task :rebuild => [ :drop, :create, :migrate ]

  desc "Runs migrations on the current database"
  task :migrate => :require do
    Sequel.extension :migration
    if (sf = MIGRATIONS_FOLDER/'superuser').exists?
      Sequel::Migrator.run(SUPERUSER_DATABASE, , table: 'superuser_migrations')
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

end
