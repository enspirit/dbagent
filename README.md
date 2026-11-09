[![Integration](https://github.com/enspirit/dbagent/actions/workflows/integration.yml/badge.svg?branch=master)](https://github.com/enspirit/dbagent/actions/workflows/integration.yml)

# DbAgent, a ruby tool to migrate, spy and seed relational databases

DbAgent helps managing a relational database lifecyle through three main tools:

* Migrations: powered by [Sequel](http://sequel.jeremyevans.net/), migrate as simply as `rake db:migrate`. Supports both superuser and normal user migrations.

* Spy: using [Shemaspy](http://schemaspy.sourceforge.net/), get your database schema browsable at any moment, through a simple web interface.

* Seed: maintain, install and flush database content as datasets, organized hierarchically in .json files. Very handy for automated tests, for instance.

## Get started using Docker

DbAgent is expected to be used as its Docker agent, available as `enspirit/dbagent`. Simply mount migrations and data folders, and you're ready to go.

See the examples folder for details.

## Available environment variables

* `DBAGENT_ROOT_FOLDER`                Main folder where data, migrations and viewpoints can be found
* `DBAGENT_LOGLEVEL`                   Log level to use for dbagent messages (defaults to `WARN`)
* `DBAGENT_LOGSQL`                     Low Sequel's SQL queries (defaults to `no`)
* `DBAGENT_ADAPTER`                    Sequel's adapter (defaults to `postgres`)
* `DBAGENT_HOST`                       Database server host (defaults to `localhost`)
* `DBAGENT_PORT`                       Database server port (defaults to `5432`)
* `DBAGENT_DB`                         Database name (defaults to `suppliers-and-parts`)
* `DBAGENT_USER`                       Database user (defaults to `dbagent`)
* `DBAGENT_PASSWORD`                   Database password (defaults to `dbagent`)
* `DBAGENT_DATABASES`                  List of database names for multi-db mode (no default)
* `DBAGENT_SOCKET`                     Database server socket (if host/port is not used)
* `DBAGENT_SUPER_USER`                 Superuser name (postgres only)
* `DBAGENT_SUPER_DB`                   Superuser database (postgres only)
* `DBAGENT_SUPER_PASSWORD`             Superuser password (postgres only)
* `DBAGENT_WAIT_TIMEOUT_IN_SEC`        Timeout in seconds before db:wait_server and db:wait give up
* `DBAGENT_VIEWPOINT`                  Bmg viewpoint (class name) when using db:flush
* `DBAGENT_MIGRATIONS_TABLE`           The table containing the list of migrations (defaults to `schema_migrations`)
* `DBAGENT_SUPERUSER_MIGRATIONS_TABLE` The table containing the list of superuser migrations (defaults to `superuser_migrations`)
* `DBAGENT_IGNORED_FLUSH_FIELDS`.      Fields ignored when db:flush compares data to dump/skip a table
* `DBAGENT_SEED_DISABLE_TRIGGERS`      Load seeds with triggers & FK checks off (postgres only, see below)
* `DBAGENT_SEED_SKIP_UNCHANGED`        Skip a seed install when nothing changed since the last one (see below)

## Available rake tasks

The following rake tasks helps you managing the database. They must typically be executed on the docker container.

```
rake db:check-seeds          # Checks that all seeds can be installed correctly
rake db:create               # Creates an fresh new user & database (USE WITH CARE)
rake db:drop                 # Drops the user & database (USE WITH CARE)
rake db:flush[to,inherits?]  # Flushes the database as a particular data set
rake db:migrate              # Runs migrations on the current database
rake db:ping                 # Pings the database, making sure everything's ready for migration
rake db:rebuild              # Rebuilds the database from scratch (USE WITH CARE)
rake db:repl                 # Opens a database REPL
rake db:seed[from,include_parents?]  # Seeds the database with a particular data set
rake db:apply[from,include_parents?] # Applies a data set without emptying any table
rake db:spy                  # Dumps the schema documentation into database/schema
rake db:backup               # Makes a database backup to the backups folder
rake db:restore[match]       # Restore the last matching database backup file from backups folder
rake db:revive               # Shortcut for both db:restore and db:migrate
rake db:wait_server          # Waits until the postgresql host seems available
rake db:wait                 # Waits until the postgresql database seems available
rake db:tables               # List tables with those with fewer dependencies first
rake db:dependencies[of]     # List tables that depend of a given one
```

## Available webservices

```
GET  /schema/                # Browser the database schema (requires a former `rake db:spy`)
POST /seeds/install?id=...   # Install a particular dataset, id is the name of a folder in `data` folder
POST /seeds/apply?id=...     # Apply a particular dataset, emptying no table
POST /seeds/flush?id=...     # Flushes the current database content as a named dataset
```

`POST /seeds/install` (and `rake db:seed`) accept an optional `include_parents`
flag (default `true`). Seeds are organized hierarchically — a seed may `inherit`
another via its `metadata.json`. With `include_parents=false`, only the tables
of the named seed itself are reset; the tables coming from the inherited
parent seed(s) are left untouched.

This is useful to speed up test suites that reseed between every test: put the
large, never-written reference tables in a parent seed (e.g. `test/core`) and
the smaller, test-mutated tables in a child seed that inherits it (e.g.
`test/base`). Reinstalling the child with `include_parents=false` then skips
reloading the static reference data. It is only sound when the parent (static)
tables are genuinely never written by the tests, and no parent table has a
foreign key pointing into a child table.

```
POST /seeds/install?id=test/base&include_parents=false
```

### Applying a slice to a database that already holds data

`install` empties every table the seed names before refilling it, so it can
only ever be pointed at a database whose entire content *is* that seed — never
at a production one. `rake db:apply` / `POST /seeds/apply` run the same seed
without emptying anything: the `before_seeding.sql` script, then the rows, then
`after_seeding.sql`, in one transaction.

That is what a seed carrying a *slice* of the database needs — one project, one
tenant, one customer. Deciding which rows are replaced becomes the seed's own
job, written in its `before_seeding.sql`:

```sql
DELETE FROM order_lines WHERE tenant = 'acme';
DELETE FROM orders      WHERE tenant = 'acme';
```

A seed written that way is idempotent: applying it installs it, applying it
again updates it, and nothing outside the slice is ever touched. `db:flush`
with a `DBAGENT_VIEWPOINT` restricting the database to one tenant is the
natural way to produce one.

`include_parents` defaults to `false` here, the other way round from `install`:
a slice is self-contained, and the rows of the seed it inherits from are
typically already in the database being added to.

### Seeding with triggers disabled

A seed is a complete snapshot, so a trigger that derives rows (say, an
`AFTER INSERT` on `users` that also writes `user_roles`) re-derives state the
data files already carry, and the two collide. Setting
`DBAGENT_SEED_DISABLE_TRIGGERS=true` makes `install` load seeds with
`session_replication_role = 'replica'`, which suppresses user triggers and
foreign key checks for the duration of the transaction — the same thing
`pg_dump --disable-triggers` does.

This is off by default, and worth keeping off unless you need it: with foreign
key checks suppressed, referential errors inside a seed load silently, and
`rake db:seed` / `rake db:check-seeds` stop reporting them. It is PostgreSQL
only (ignored, with a warning, on other adapters) and setting
`session_replication_role` requires superuser privileges on most servers.

### Skipping installs that would change nothing

Test runners such as webspicy reinstall a seed before every test case, and many
test cases write nothing: reads, refused requests. Each of those reinstalls
rewrites every table of the seed to the state it is already in.

`DBAGENT_SEED_SKIP_UNCHANGED=true` makes `install` skip such an install. It
relies on the database driver's *data version*: an opaque value that changes
whenever committed data changes, so that two equal data versions mean nothing
was written in between, by anyone (the application under test, another dbagent
process, `rake db:seed`). After each install, the process remembers the seed,
its files (and when they last changed on disk) and the data version; the next
install of the same seed, with the same files, is skipped while the data version
is the same.

| Driver     | Data version                    | Not seen                 |
|------------|---------------------------------|--------------------------|
| PostgreSQL | WAL insert position             | writes to `UNLOGGED` tables |
| MySQL      | none yet: installs never skipped |                         |
| MSSQL      | none yet: installs never skipped |                         |

The check errs on the safe side: a data version may change without the data
changing (on PostgreSQL, autovacuum and checkpoints move the WAL too), which
only makes it install again when it did not need to. Do not enable it when a
seed fills tables whose writes the driver does not see. A write landing between
the end of an install and the reading of the data version would be taken as
part of the seed: harmless for a test runner that waits for the install to
answer before calling anything else.

It is off by default. On a driver without a data version, it logs a warning and
always installs. Skipped installs are logged at `INFO` level.

## Multiple databases mode

DbAgent supports managing multiple databases within the same directory structure via the (optional) `DBAGENT_DATABASES`
environment variables. We only support multiple databases on the same server with the same user/password pair, for now.

In multiple database mode, migrations and seeds simply have the database name as intermediate folder. For instance
`data/empty/db1` and `data/empty/db2` (see `examples/multi-db`).

All rake tasks will be execute on each database, in turn. For instance, `bundle exec rake db:ping` will ping each
database in turn.

The `DBAGENT_DATABASES` env var may contain a commalist of database names. You can also set it to `/from-empty-seeds`
for auto-discovery. In that case, your empty seed must contain a folder for each database, with the same name.

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

## Contribute

Please use github issues and pull requests for all questions, bug reports,
and contributions. Don't hesitate to get in touch with us with an early code
spike if you plan to add non trivial features.

## Licence

This software is distributed by Enspirit SRL under a MIT Licence. Please
contact Bernard Lambeau (blambeau@gmail.com) with any question.

Enspirit (https://enspirit.be) and Klaro App (https://klaro.cards) are both
actively using and contributing to the library.
