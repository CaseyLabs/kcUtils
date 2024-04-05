kcServiceName := "kc-dev"

.PHONY: build run

build:
	docker build \
	--build-arg kcUserId=$(shell id -u) \
	--build-arg kcGroupId=$(shell id -g) \
	-t ${kcServiceName} .

run:
	# Enter the container shell:
	# (Optional: mount sync folder to container volume)
	docker run -it \
		--volume ${HOME}/sync:/home/user/sync \
		--name ${kcServiceName} \
		--hostname ${kcServiceName} \
		--rm ${kcServiceName}