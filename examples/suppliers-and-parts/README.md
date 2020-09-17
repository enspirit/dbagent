# Todo list database managed through DbAgent

This example provides a basic configuration to maintaing a TODO list database.

## Get started

```
docker-compose up -d
```

Let's create, migrate, populate and spy the database:

```
docker-compose exec dbagent bundle exec rake db:create db:ping
docker-compose exec dbagent bundle exec rake db:migrate db:spy
docker-compose exec dbagent bundle exec rake "db:seed[base]"
```

You can browse the database schema in a web browser:

```
http://127.0.0.1:8080/schema/
```
