## Better defaults for make (thanks https://tech.davis-hansson.com/p/make/)
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

DATA_PATH = $(PWD)/examples/suppliers-and-parts
DOCKER_TAG := $(or ${DOCKER_TAG},${DOCKER_TAG},latest)

ps:
	docker ps

image:
	docker build . -t enspirit/dbagent:${DOCKER_TAG}

image.push: image
	docker push enspirit/dbagent:${DOCKER_TAG}

prepare: image
	docker network create agent-network || true
	docker run -d --rm --name db -v db-data:/var/lib/postgresql/data --env POSTGRES_USER=dbagent --env POSTGRES_DB=suppliers-and-parts --env POSTGRES_PASSWORD=dbagent --network=agent-network --user $(id -u):$(id -g) postgres
	docker run -d --rm --name dbagent --env DBAGENT_HOST=db -v$(PWD)/lib:/home/data/lib -v $(DATA_PATH)/data:/home/app/data -v $(DATA_PATH)/migrations:/home/app/migrations -v $(DATA_PATH)/backups:/home/app/backups -v $(DATA_PATH)/viewpoints:/home/app/viewpoints -v $(PWD)/tasks:/home/app/tasks -v $(PWD)/lib:/home/app/lib --network=agent-network --user $(id -u):$(id -g) enspirit/dbagent
	docker exec -t dbagent bundle install
	docker ps

exec_test:
	docker exec -t dbagent bundle exec rake test
	docker exec -t dbagent bundle exec rake db:wait db:ping
	docker exec -t dbagent bundle exec rake db:migrate
	docker exec -t dbagent bundle exec rake db:seed[base]
	docker exec -t dbagent bundle exec rake db:insert_script[base]
	docker exec -t dbagent bundle exec rake db:flush[tmp]
	docker exec -e DBAGENT_VIEWPOINT=DbAgent::Viewpoint::InCity -t dbagent bundle exec rake db:flush[incity]
	docker exec -t dbagent bundle exec rake db:flush_empty[new_empty]
	docker exec -t dbagent bundle exec rake db:spy
	docker exec -t dbagent bundle exec rake db:backup

down:
	docker stop db dbagent || true
	docker network rm agent-network || true

test: prepare exec_test down

package: prepare
	bundle exec rake package

gem.push:
	ls pkg/dbagent*.gem | xargs gem push
