PORT ?= 5011

.PHONY: image up down test

image:
	docker compose build

up:
	PORT=$(PORT) docker compose up -d
	@echo "Server is running at http://localhost:$(PORT)"

down:
	docker compose down

test:
	docker compose run --rm --no-deps \
	    -v $(CURDIR)/../..:/app \
	    --entrypoint rove app /app/sample/11-nested/11-nested.asd
