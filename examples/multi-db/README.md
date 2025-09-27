# Multiple databases managed through DbAgent

This example provides a basic configuration to maintaing multiple databases
on the same postgresql server.

## Get started

```
docker-compose up
```

In another terminal, let migrate & spy the database:

```
docker-compose exec dbagent bash
rake db:ping
rake db:migrate
rake db:spy
```

You can browse the database schema in a web browser:

```
http://127.0.0.1:8080/schema/
```

Let now install some data, then look at it:

```
echo "SELECT * FROM todo" | rake db:repl
curl -X POST http://127.0.0.1/seeds/install -d "id=test"
echo "SELECT * FROM todo" | rake db:repl
```
