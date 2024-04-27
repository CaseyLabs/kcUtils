# `kcRepo`  
  
A git repository template for new projects.  

## Defaults  
  
Project config settings as set in `./config/settings.env`  
  
`docker run` mounts project folders as volume mounts:  

- `./app` --> `/home/user/app`  
- `./input` --> `/home/user/input`  
- `./output` --> `/home/user/output`  

These should be changed to `DOCKER COPY` when building an image for distribution.  

## Setup  

- `make build`: Build the app
- `make run`: Run the app  
- `make shell`: Enter a container shell
