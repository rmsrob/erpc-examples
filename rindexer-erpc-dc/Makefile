ifneq (,$(wildcard ./.env))
    include .env
    export
endif

cmd-exists-%:
	@hash $(*) > /dev/null 2>&1 || \
		(echo "ERROR: '$(*)' must be installed and available on your PATH."; exit 1)

.PHONY: tpl
tpl: cmd-exists-gomplate
	@if [ ! -f .env ]; then \
		echo "ERROR: Missing .env file."; \
		exit 1; \
	fi
	gomplate -f erpc.example.yaml -o erpc.yaml

.PHONY: dcup
dcup: cmd-exists-docker-compose tpl
	@docker-compose up -d

.PHONY: start
start: cmd-exists-rindexer dcup
	@echo "Waiting for services to be ready..."
	@timeout=60; \
	while ! docker-compose ps | grep -q "healthy"; do \
	    sleep 5; \
	    echo "Waiting for containers to become healthy..."; \
	    timeout=$$((timeout - 5)); \
	    if [ $$timeout -le 0 ]; then \
	        echo "ERROR: Timed out waiting for containers to become healthy."; \
	        exit 1; \
	    fi; \
	done
	@echo "All services are up and healthy."
	@rindexer start all

,PHONY: test-rindexer-erpc-dc
test-erpc-compose: cmd-exists-curl
	@sh test-rindexer-erpc-dc.sh

.PHONY: dcdown
dcdown:
	@echo "Stopping docker-compose services..."
	docker-compose down

.PHONY: stop
stop: stop dcdown
	@echo "Removing containers and volumes..."
	docker-compose down --volumes
	@docker volume rm ${PGSQL_VOLUME_NAME} ${REDIS_VOLUME_NAME} || true
	@echo "Cleanup complete."