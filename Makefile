# Ensure the targets are always run. Needed to prevent side effects when running with "-q"
.PHONY: build docker local live localup localmsg liveup pull

# Bring down any dependencies and build the image
build: docker

# Rebuild the local Docker image
docker:
	@docker build -t travix/elastalert:latest .

localup:
	@docker-compose up -d --build

# localmsg:
# 	@echo ""
# 	${INFO} "Go to http://localhost:$(shell docker port $(shell docker-compose ps -q app) | awk '{print $$3}' | awk -F: '{print $$2}') to use Elastalert!"
# 	@echo "Username: admin"
# 	@echo "Password: admin"
# 	@echo ""

pull:
	@docker pull travix/elastalert:latest

# local: localup localmsg
local: localup

# Cosmetics
GREEN := "\033[1;32m"
NULL := "\033[0m"
RED := "\033[1;31m"
YELLOW := "\033[1;33m"

# Shell functions
INFO := @bash -c '\
	printf $(GREEN); \
	echo "=> $$1"; \
	printf $(NULL)' VALUE

WARNING := @bash -c '\
	printf $(YELLOW); \
	echo "=> $$1"; \
	printf $(NULL)' VALUE

ERROR := @bash -c '\
	printf $(RED); \
	echo "=> $$1"; \
	printf $(NULL)' VALUE
