DATA_PATH = $(PWD)/examples/suppliers-and-parts

image:
	docker build . -t enspirit/dbagent

prepare:
	docker network create agent-network || true
	docker run -d --rm --name db -v db-data:/var/lib/postgresql/data --env POSTGRES_USER=dbagent --env POSTGRES_DB=suppliers-and-parts --env POSTGRES_PASSWORD=dbagent --network=agent-network postgres 
	docker run -d --rm --name dbagent --env DBAGENT_HOST=db -v $(DATA_PATH)/data:/home/app/data -v $(DATA_PATH)/migrations:/home/app/migrations -v $(DATA_PATH)/backups:/home/app/backups --network=agent-network enspirit/dbagent
	docker exec -it dbagent bundle install

test: prepare
	docker exec -it dbagent bundle exec rake db:migrate db:seed
	docker exec -it dbagent bundle exec rake test

clean:
	docker stop db dbagent || true
	docker network rm agent-network || true
