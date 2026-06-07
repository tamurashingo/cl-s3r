PORT ?= 5001

.PHONY: image up down

image:
	docker compose build

up:
	PORT=$(PORT) docker compose up -d
	@echo "Server is running at http://localhost:$(PORT)"

down:
	docker compose down

