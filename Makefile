DATA_PATH = $(PWD)/examples/suppliers-and-parts
DOCKER_TAG := $(or ${DOCKER_TAG},${DOCKER_TAG},latest)

image:
	docker build . -t enspirit/dbagent:${DOCKER_TAG}

image.push: image
	docker push enspirit/dbagent:${DOCKER_TAG}

prepare: image
	docker network create agent-network || true
	docker run -d --rm --name db -v db-data:/var/lib/postgresql/data --env POSTGRES_USER=dbagent --env POSTGRES_DB=suppliers-and-parts --env POSTGRES_PASSWORD=dbagent --network=agent-network --user $(id -u):$(id -g) postgres
	docker run -d --rm --name dbagent --env DBAGENT_HOST=db -v$(PWD)/lib:/home/data/lib -v $(DATA_PATH)/data:/home/app/data -v $(DATA_PATH)/migrations:/home/app/migrations -v $(DATA_PATH)/backups:/home/app/backups -v $(DATA_PATH)/viewpoints:/home/app/viewpoints --network=agent-network --user $(id -u):$(id -g) enspirit/dbagent
	docker exec -t dbagent bundle install

exec_test:
	docker exec -t dbagent bundle exec rake db:wait db:ping
	docker exec -t dbagent bundle exec rake db:migrate
	docker exec -t dbagent bundle exec rake db:seed[base]
	docker exec -t dbagent bundle exec rake db:flush[tmp]
	docker exec -e DBAGENT_VIEWPOINT=DbAgent::Viewpoint::InCity -t dbagent bundle exec rake db:flush[incity]
	docker exec -t dbagent bundle exec rake db:flush_empty[new_empty]
	docker exec -t dbagent bundle exec rake db:spy
	docker exec -t dbagent bundle exec rake db:backup
	docker exec -t dbagent bundle exec rake test

clean:
	docker stop db dbagent || true
	docker network rm agent-network || true

test: prepare exec_test clean

package: prepare
	bundle exec rake package

gem.push:
	ls pkg/dbagent*.gem | xargs gem push
