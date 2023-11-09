enter:
	docker run --env-file envs/example.env -it --platform linux/amd64 kitchenscreen /bin/bash

run:
	docker run --env-file envs/example.env -it --platform linux/amd64 kitchenscreen bundle exec ruby generate.rb

runz:
	docker run --env-file envs/production.env -it --platform linux/amd64 kitchenscreen bundle exec ruby generate.rb

build:
	docker build -f dockerfiles/Dockerfile.firefox -t kitchenscreen --platform linux/amd64 .
