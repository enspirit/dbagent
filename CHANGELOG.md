## 3.9.5 - 2025-10-15

* The seeder now considers the same json string as being same table data, which
  is complementary to a set comparison (because of timezone irrelevant differences).

## 3.9.4 - 2025-10-07

* Use ruby 3.4 as base docker image

## 3.9.3 - 2025-10-07

* Don't use a composite if DBAGENT_DATABASES is present but empty

## 3.9.2 - 2025-10-02

* Fix Composite to avoid creating new database connecions everytime a seed is
  done on web api.

* Moved to puma instead of thin, with only one thread.

## 3.9.1 - 2025-09-30

* `rake db:flush` now supports a second argument, which is the seed to inherit
  from. Tables whose data is unchanged are no longer flushed on disk.

## 3.9.0 - 2025-09-29

* Add support for multiple databases, via a DBAGENT_DATABASES environment
  variables

* Add DbHandler#fork and DbHandler#fork_config to ease with multiple databases
  setups.

* The webapp now returns a friendly error message when seeding fails.

* Logs shgow which .sql and .json files are used when seeding, for easier
  debugging

## 3.8.3 - 2024-06-11

* Add support for migrations table configuration.

## 3.8.2 - 2024/04/19

* Don't run superadmin migrations if none.

## 3.8.1 - 2024/04/19

* Complete MySQL handler regarding db:create and db:drop.

## 3.8.0 - 2024/04/04

* Add support for PostgreSQL schemas other than public. Names of seed files can
  use a `schema.table` scheme, while viewpoints expect a `schema__table` method
  name.

## 3.7.0 - 2024/02/23

* Upgraded base image to ruby 3.3

* schemaspy.jar upgraded to 6.2.4

* postgresql.jar upgraded to 42.7.6

* bmg upgraded to 0.21.x

* General ruby bundle update

## 3.6.0 - 2023/10/17

* Version bump with new docker image bringing psql and pg_dump 15.x

* General bundle update.

## 3.5.0 - 2023/06/19

* Added DBAGENT_WAIT_TIMEOUT_IN_SEC, used by db:wait_server and db:wait.
  Default value is 15. Larger values may be needed in install processes
  where a large database is recreated before being migrated.

* Improved db:wait_server and db:wait regarding printed debug information.

## 3.4.0 - 2023/06/15

* schemaspy.jar upgraded to 6.2.2

* postgresql.jar upgraded to 42.6.0

* Add SCHEMA_SPY_ARGS environment variable, used by `rake db:spy`

## 3.3.0 - 2023/04/17

* Add db:insert_script that prints an SQL INSERT script from a given seed.
  No truncate/delete is done at all.

## 3.2.1 - 2022/07/13

* Correctly discover MySQL handler when mysql2 is used.

## 3.2.0 - 2022/06/17

* Base image now uses ruby 3.1

* psql version upgraded to 13.7

* predicate >= 2.7, bmg >= 0.20, sexpr >= 1.0

* Use thin as web server
## 3.1.0 - 2021/09/10

* Add support for a `before_seeding.sql` file in root data folder. The script
  will be executed before the seeder starts emptying the database and can be
  used for, e.g., disable all foreign key constraints.

* Add support for `after_seeding.sql` scripts in data folders. Those scripts
  will be executed after all tables have been filled up.

  Unlike `before_seeding.sql`, those files can be put in subfolders. They are
  executed in reverse order of inheritance (deepest levels first), but all at
  once after the tables have been filled up.

## 3.0.1 - 2021/08/24

* Fix seeder when used through the webapp.
## 3.0.0 - 2021/08/17

This release introduces many breaking changes, especially if you use DbAgent
programatically. Rake tasks and folders are unchanged, so upgrade should not be
a lot of work.

Breaking changes:
* Removes all global state (e.g. SEQUEL_DATABASE, ...).
* Upgraded schemaspy to 6.1 and postgresql jdbc driver to 42
* Removed .jar files from repository, they are now downloaded by Dockerfile
* The image no longer runs as root, but as app
* Consequently, the webapp now listens on port 9292, no longer on 80

Improvements:
* Introduce various handlers for MySQL, PostgreSQL and MSSQL
* db:tables and db:dependencies no longer fail in presence of FK cycles
* db:repl & db:backup no longer ask for the db password if known (postgres)
* Added db:flush_empty that creates an initial seed from infered tables list
  (taking dependency ordering into account)

Others:
* Clarified licencing (MIT)
* dbagent is now also an official ruby gem

## 2.2.2 - 2021/07/16

* Add support for version numbers in `db:migrate[...]`

## 2.2.1 - 2020/10/27

* Add a Typecheck utility viewpoint.
## 2.2.0 - 2020/10/27

* Improve logging: exposing now the `DBAGENT_LOGLEVEL`
  and `DBAGENT_LOGSQL` environment variables.

* Add support for (optional) Bmg viewpoints in db:flush,
  through a viewpoints/ folder in root directory

## 2.1.1 - 2020/09/17

* Fix Dockerfile to listen to 0.0.0.0 and not only on
  127.0.0.1. The fix has been backported to 2.0 and 2.1
  docker images.

## 2.1.0 - 2020/09/17

* db:restore now support an optional argument to list the
  candidate backup files, based on a word:

      rake db:restore[production]

* db:dependencies[table] lists all tables that depends on
  the given table, or of a table that depends on it, based
  on foreign keys.

## 2.0.0 - 2020/09/17

* The default environment variables are set to connect to
  the suppliers-and-parts database on localhost, using a
  dbagent/dbagent user/password pair. This aims at making
  hacking on dbagent itself easier. It should not break
  existing deployments having all environment variables
  properly set.

* Migrated out of ruby passenger, to simply use ruby 2.7
  and rackup on port 80. This should not break anything, as
  the public interface did not change (rake commands, web
  services).

* The backups/ and schema/ folders are now part of the
  base images (as empty folders). This might break an
  existing Dockerfile that mkdir them without the -p flag.

* Since Sequel dependency has been upgraded to ">= 5", some
  migrations may be broken (if they use the fact that the `up`
  method received the db as argument). Simply use `self`
  instead of `db` and all should be fine.

## 1.x

DbAgent first version.
