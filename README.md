# DbAgent, a ruby tool to migrate, spy and seed PostgreSQL databases

DbAgent helps managing a relational database lifecyle through three main tools:

* Migrations: powered by [Sequel](http://sequel.jeremyevans.net/), migrate as simply as `rake db:migrate`. Supports both superuser and normal user migrations.

* Spy: using [Shemaspy](http://schemaspy.sourceforge.net/), get your database schema browsable at any moment, through a simple web interface.

* Seed: maintain, install and flush database content as datasets, organized hierarchically in .json files. Very handy for automated tests, for instance.

## Get started using Docker

DbAgent is expected to be used as its Docker agent, available as `enspirit/dbagent`. Simply mount migrations and data folders, and you're ready to go.

See the examples folder for details.

## Available rake tasks

The following rake tasks helps you managing the database. They must typically be executed on the docker container.

```
rake db:check-seeds  # Checks that all seeds can be installed correctly
rake db:create       # Creates an fresh new user & database (USE WITH CARE)
rake db:drop         # Drops the user & database (USE WITH CARE)
rake db:flush[to]    # Flushes the database as a particular data set
rake db:migrate      # Runs migrations on the current database
rake db:ping         # Pings the database, making sure everything's ready for migration
rake db:rebuild      # Rebuilds the database from scratch (USE WITH CARE)
rake db:repl         # Opens a database REPL
rake db:seed[from]   # Seeds the database with a particular data set
rake db:spy          # Dumps the schema documentation into database/schema
rake db:backup       # Makes a database backup to the backups folder
rake db:restore      # Restore the last database backup from backups folder
rake db:revive       # Shortcut for both db:restore and db:migrate
```

## Available webservices

```
GET  /schema/                # Browser the database schema (requires a former `rake db:spy`)
POST /seeds/install?id=...   # Install a particular dataset, id is the name of a folder in `data` folder
POST /seeds/flush?id=...     # Flushes the current database content as a named dataset
```
