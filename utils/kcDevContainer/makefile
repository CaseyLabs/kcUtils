#| # kcDevContainer
#|   
#| `kcDevContainer` is standardized Docker development environment container.   
#|   
#| ## Setup  
#|   
#| ```sh
#| make build
#| ```  
#|   
#| ## Usage  
#|
#| Run and enter the container's shell:
#|
#| ```sh
#| make run
#| ```  
#|
#| ## Example
#| ![kcDevContainer demo image](./demo.gif)

ENVFILE = ./config/settings.env
include $(ENVFILE)
export $(shell sed '/^\#/d; s/=.*//' $(ENVFILE))

# Available Makefile stages
.PHONY: build run

#| ## Setup

#| - `make build`: Build the app
build:
	docker build --no-cache -t ${kcServiceName} .

cached-build:
	docker build -t ${kcServiceName} .

#| - `make run`: Run the app
run: cached-build
	docker run \
		-v ${PWD}:/home/user/workdir \
		-it ${kcServiceName} /bin/zsh