.PHONY: image test clean

image:
	docker compose build

test:
	docker compose run --rm playwright

clean:
	docker compose down --rmi local
