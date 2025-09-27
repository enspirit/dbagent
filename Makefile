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
	rm -rf .volumes
	docker network create agent-network || true
	docker run -d --rm --name db -v ./.volumes/pgdata:/var/lib/postgresql/data --env POSTGRES_USER=dbagent --env POSTGRES_DB=suppliers-and-parts --env POSTGRES_PASSWORD=dbagent --network=agent-network postgres:15
	docker run -d --rm --name dbagent --env DBAGENT_HOST=db --env DBAGENT_ROOT_FOLDER=/home/app/examples/suppliers-and-parts -v $(PWD)/examples:/home/app/examples -v $(PWD)/lib:/home/app/lib -v $(PWD)/spec:/home/app/spec -v $(PWD)/tasks:/home/app/tasks --network=agent-network --user $(id -u):$(id -g) enspirit/dbagent
	docker exec -t dbagent bundle install
	docker ps

exec_test:
	docker exec -t dbagent sh -c '\
		set -e; \
		bundle exec rake db:wait db:ping; \
		bundle exec rake db:migrate; \
		bundle exec rake test; \
		bundle exec rake db:check-seeds; \
		bundle exec rake db:seed[base]; \
		bundle exec rake db:insert_script[base]; \
		bundle exec rake db:flush[tmp]; \
		rm -rf examples/suppliers-and-parts/data/tmp
		bundle exec rake db:flush_empty[new_empty]; \
		rm -rf examples/suppliers-and-parts/data/new_empty; \
		bundle exec rake db:spy; \
		bundle exec rake db:backup; \
	'

down:
	docker stop db dbagent || true
	docker network rm agent-network || true

test: down prepare exec_test down

package:
	bundle install
	bundle exec rake package

gem.push:
	ls pkg/dbagent*.gem | xargs gem push
