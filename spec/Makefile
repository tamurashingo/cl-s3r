PORT ?= 5010

.PHONY: spec-sheet image up down

spec-sheet: image up
	@echo "Spec sheet is running at http://localhost:$(PORT)/spec-sheet"

image:
	docker compose build

up:
	PORT=$(PORT) docker compose up -d

down:
	docker compose down
