# DbAgent, a ruby tool to migrate, spy and seed relational databases

DbAgent helps managing a relational database lifecyle through three main tools:

* Migrations: powered by [Sequel](http://sequel.jeremyevans.net/), migrate as simply as `rake db:migrate`. Supports both superuser and normal user migrations.

* Spy: using [Shemaspy](http://schemaspy.sourceforge.net/), get your database schema browsable at any moment, through a simple web interface.

* Seed: maintain, install and flush database content as datasets, organized hierarchically in .json files. Very handy for automated tests, for instance.

## Get started using Docker

DbAgent is expected to be used as its Docker agent, available as `enspirit/dbagent`. Simply mount migrations and data folders, and you're ready to go.

See the examples folder for details.

## Available environment variables

* `DBAGENT_ROOT_FOLDER`     Main folder where data, migrations and viewpoints can be found
* `DBAGENT_LOGLEVEL`        Log level to use for dbagent messages (defaults to `WARN`)
* `DBAGENT_LOGSQL`          Low Sequel's SQL queries (defaults to `no`)
* `DBAGENT_ADAPTER`         Sequel's adapter (defaults to `postgres`)
* `DBAGENT_HOST`            Database server host (defaults to `localhost`)
* `DBAGENT_PORT`            Database server port (defaults to `5432`)
* `DBAGENT_DB`              Database name (defaults to `suppliers-and-parts`)
* `DBAGENT_USER`            Database user (defaults to `dbagent`)
* `DBAGENT_PASSWORD`        Database password (defaults to `dbagent`)
* `DBAGENT_SOCKET`          Database server socket (if host/port is not used)
* `DBAGENT_SUPER_USER`      Superuser name (postgres only)
* `DBAGENT_SUPER_DB`        Superuser database (postgres only)
* `DBAGENT_SUPER_PASSWORD`  Superuser password (postgres only)
* `DBAGENT_VIEWPOINT`       Bmg viewpoint (class name) when using db:flush

## Available rake tasks

The following rake tasks helps you managing the database. They must typically be executed on the docker container.

```
rake db:check-seeds    # Checks that all seeds can be installed correctly
rake db:create         # Creates an fresh new user & database (USE WITH CARE)
rake db:drop           # Drops the user & database (USE WITH CARE)
rake db:flush[to]      # Flushes the database as a particular data set
rake db:migrate        # Runs migrations on the current database
rake db:ping           # Pings the database, making sure everything's ready for migration
rake db:rebuild        # Rebuilds the database from scratch (USE WITH CARE)
rake db:repl           # Opens a database REPL
rake db:seed[from]     # Seeds the database with a particular data set
rake db:spy            # Dumps the schema documentation into database/schema
rake db:backup         # Makes a database backup to the backups folder
rake db:restore[match] # Restore the last matching database backup file from backups folder
rake db:revive         # Shortcut for both db:restore and db:migrate
```

## Available webservices

```
GET  /schema/                # Browser the database schema (requires a former `rake db:spy`)
POST /seeds/install?id=...   # Install a particular dataset, id is the name of a folder in `data` folder
POST /seeds/flush?id=...     # Flushes the current database content as a named dataset
```

## Hacking on dbagent

### Installing the library

```
bundle install
```

### Preparing your computer

The tests require a valid PostgreSQL installation with the suppliers-and-parts
database installed. A `dbagent` user would be needed on the PostgreSQL installation
to bootstrap the process.

```
sudo su postgres -c 'createuser --createdb dbagent -P'
```

DbAgent tries to connect to the suppliers-and-parts with a dbagent/dbagent user/password
pair by default. If you change the database name, user, or password please adapt the
environment variables accordingly in the commands below.

### Installing the example database

```
DBAGENT_ROOT_FOLDER=examples/suppliers-and-parts bundle exec rake db:create db:migrate db:seed['base']
```

## Contributions

### Running test

To run the test you need to have `Docker` on your computer.

Run: 
```
make test
```

Don't forget to delete created ressources for the tests bun running:
```
make clean
```