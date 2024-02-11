VERBOSE ?= 0
COMPOSE_FILE ?= docker-compose.yml

build:
	docker compose --file $(COMPOSE_FILE) build

start:
ifeq ($(VERBOSE),0)
	./scripts/start_node.sh
else
	./scripts/start_node.sh -v
endif

stop:
	docker compose --file $(COMPOSE_FILE) down --volumes

sandwich-attack:
	docker compose --file $(COMPOSE_FILE) exec localsecret-2 ./scripts/sandwich-attack.sh

receiver-privacy-attack:
	docker compose --file $(COMPOSE_FILE) exec localsecret-2 ./scripts/test_snip20.sh

balance-privacy-attack:
	docker compose --file $(COMPOSE_FILE) exec localsecret-2 ./scripts/test_balance.sh

clean:
	-rm -rf \
		adv_key \
    	adv_value \
		backup_adv_key \
    	backup_adv_value \
    	backup_victim_key \
    	kv_store \
    	victim_key
