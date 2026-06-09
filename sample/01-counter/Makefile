PORT ?= 5001

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
	    --entrypoint rove app /app/sample/01-counter/01-counter.asd

