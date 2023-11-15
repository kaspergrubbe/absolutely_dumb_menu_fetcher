.PHONY: push

enter:
	@docker run --env-file envs/example.env -it --platform linux/amd64 kitchenscreen /bin/bash

run:
	@docker run --env-file envs/example.env -it --platform linux/amd64 kitchenscreen bundle exec ruby generate.rb

build:
	@docker build -f dockerfiles/Dockerfile.firefox -t kitchenscreen --platform linux/amd64 .

dive:
	@dive kitchenscreen

push:
ifndef VERSION
	$(error VERSION is not set. Please provide a value.)
endif
	@docker build -f dockerfiles/Dockerfile.firefox -t kaspergrubbe/absolutely_dumb_menu_fetcher:$(VERSION) --platform linux/amd64 .
	@docker push kaspergrubbe/absolutely_dumb_menu_fetcher:$(VERSION)
	@git tag v$(VERSION)
	@git push github v$(VERSION)
