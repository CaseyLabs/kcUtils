#| # `kcBlog/makefile`
#|
#| This makefile is used for building and running this project.

kcServiceName := "kc-blog"

.PHONY: build run shell

#| ## Commands

#| - `make build`: Build the app
build:
	# Perform a non-cached build
	docker build --no-cache -t ${kcServiceName} .

cached-build:
	# Perform a cached build
	docker build -t ${kcServiceName} .

#| - `make run`: Run the app
run: cached-build
	# run the container
	docker run -v ./output:/home/user/output ${kcServiceName}

#| - `make shell`: Enter the container shell
shell: cached-build
	# Enter a container shell
	docker run -it -v ./output:/home/user/output ${kcServiceName} /bin/sh