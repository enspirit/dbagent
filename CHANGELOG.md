# 2.1.0 - 2020/09/17

* db:restore now support an optional argument to list the
  candidate backup files, based on a word:

      rake db:restore[production]

* db:dependencies[table] lists all tables that depends on
  the given table, or of a table that depends on it, based
  on foreign keys.

# 2.0.0 - 2020/09/17

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

* the backups/ and schema/ folders are now part of the
  base images (as empty folders). This might break an
  existing Dockerfile that mkdir them without the -p flag.

# 1.x

DbAgent first version.
