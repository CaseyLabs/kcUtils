#| # `kcRepo`
#|
#| A git repository template for new projects.
#|
#| ## Defaults
#|
#| Project config settings as set in `./config/settings.env`
#|
#| `docker run` mounts project folders as volume mounts:
#|   - `./app` --> `/home/user/app`
#|   - `./input` --> `/home/user/input`
#|   - `./output` --> `/home/user/output`
#|
#| These should be changed to DOCKER COPY when building an image for distribution.

ENVFILE = ./config/settings.env
include $(ENVFILE)
export $(shell sed '/^\#/d; s/=.*//' $(ENVFILE)) 

# Available Makefile stages
.PHONY: build run shell

#| ## Setup

#| - `make build`: Build the app
build:
	docker build --no-cache -t ${kcServiceName} .

cached-build:
	docker build -t ${kcServiceName} .

#| - `make run`: Run the app
run: cached-build
	docker run \
		-v ./app:/home/user/app \
		-v ./input:/home/user/input \
		-v ./output:/home/user/output ${kcServiceName}

#| - `make shell`: Enter a container shell
shell: cached-build
	docker run \
		-v ./app:/home/user/app \
		-v ./input:/home/user/input \
		-v ./output:/home/user/output \
		-it ${kcServiceName} /bin/sh