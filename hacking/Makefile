VERBOSE ?= 0
COMPOSE_FILE ?= compose.yml

##@
##@ Local network management commands
##@
start: ##@ Start local network
ifeq ($(VERBOSE),0)
	./scripts/start_node.sh
else
	./scripts/start_node.sh -v
endif

stop: ##@ Stop local network
	docker compose --file $(COMPOSE_FILE) down --volumes


##@
##@ Attack commands
##@
sandwich-attack: ##@ run sandwich attack on a private swap (section 6.2 in paper)
	docker compose --file $(COMPOSE_FILE) exec localsecret-2 ./scripts/sandwich-attack.sh

transfer-privacy-attack: ##@ run transfer privacy attack on SNIP-20 transaction (section 5.3 in paper)
	docker compose --file $(COMPOSE_FILE) exec localsecret-2 ./scripts/transfer-privacy-attack.sh

balance-privacy-attack: ##@ run account balance privacy attack on SNIP-20
	docker compose --file $(COMPOSE_FILE) exec localsecret-2 ./scripts/balance-privacy-attack.sh


##@
##@ Other commands
##@
# Thanks to https://gist.github.com/BlackHole1 for their example at
# https://gist.github.com/prwhite/8168133?permalink_comment_id=4718682#gistcomment-4718682
help: ##@ (Default) Print listing of key targets with their descriptions
	@printf "\033[33m\nSGXOnerated attacks demonstration commands"
	@printf " (preprint: https://eprint.iacr.org/2023/378)\033[0m\n"
	@printf "\n\033[32mUsage: make <command>\033[0m\n"
	@grep -F -h "##@" $(MAKEFILE_LIST) | grep -F -v grep -F | sed -e 's/\\$$//' | awk 'BEGIN {FS = ":*[[:space:]]*##@[[:space:]]*"}; \
	{ \
		if($$2 == "") \
			pass; \
		else if($$0 ~ /^#/) \
			printf "\n%s\n", $$2; \
		else if($$1 == "") \
			printf "     %-20s%s\n", "", $$2; \
		else \
			printf "    \033[34m%-27s\033[0m %s\n", $$1, $$2; \
	}'

build: ## Build docker image used to run the local network and the attacks
	## Only supported for the development mode with COMPOSE_FILE=dev.yml
	docker compose --file $(COMPOSE_FILE) build

clean:
	-rm -rf \
		adv_key \
    	adv_value \
		backup_adv_key \
    	backup_adv_value \
    	backup_victim_key \
    	kv_store \
    	victim_key
