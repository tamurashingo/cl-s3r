COMPONENTS := accordion checkbox data-table dialog

.PHONY: component.image component.test

component.image:
	docker compose -f docker-compose.component-test.yml build

component.test:
	@for c in $(COMPONENTS); do \
		$(MAKE) component.$$c.test || exit 1; \
	done

component.%.test:
	docker compose -f docker-compose.component-test.yml run --rm --no-deps \
	    -v $(CURDIR):/app \
	    app /app/cl-s3r.components.$*.asd
