# Ensure the targets are always run. Needed to prevent side effects when running with "-q"
.PHONY: build localdown localup pull

# Bring down any dependencies and build the image
build:
	@docker build -t travix/elastalert:latest .

localdown:
	@docker-compose down -v

localup:
	@docker-compose up -d --build

pull:
	@docker pull travix/elastalert:latest

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
