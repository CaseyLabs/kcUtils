# `kcRepo`

A flexible, container-driven git repository template for new projects.

### Features

- Drop your source code into `./src`

- Change your base image in `./config/settings.cfg`

- Put your app's install commands in `./config/install.sh` and run commands in `./config/run.sh`

- Hit `./start build && ./start run`

- And boom, your app will be built and running in a container!

## Demo

![Image of kcRepo running](./demo.gif)

## Project Structure

```
.
├── config                      # Config files used during container build
│   ├── Dockerfile              
│   ├── install.sh              
│   ├── settings.cfg            
│   └── system-packages.cfg     
│
├── src                         # Source code
│   └── app.sh                  # - main app script (runs in container)
│
└── start                       # Repo Start script (Usage: ./start)
```

## Usage

### Suggested first-run command 

`./start build && ./start run`

### Other command options

- `./start build`: Build the app in a container image
- `./start rebuild`: Rebuild the container image without cached layers
- `./start run`: Run the built app in a container
- `./start shell`: Enter an app container shell
- `./start help`: Show help screen


## Configuration

Project config settings and environment variables are set in `./config/settings.cfg`

## Build Process

- This project builds and runs the source code (`./src`) in a Docker container

- The build container image is set by `KC_CONTAINER_IMAGE` (default image: `ubuntu:latest`)

- A new user will be created in the container (set by `KC_CONTAINER_USER`, default: `user`)

- The default WORKDIR is set to `/home/$KC_CONTAINER_USER`

- The new user's UID is defined by `KC_CONTAINER_UID` (default: `11001`)

## Docker Volume Mounts

- Local file/folders can be mounted automatically to new running Docker containers by setting the `KC_CONTAINER_FILEMOUNTS` variable in `./config/settings.cfg`

- If `KC_CONTAINER_FILEMOUNTS` is used, the project will change the `KC_CONTAINER_UID` to match the host user's ID (in order to prevent file permission errors).

- **Warning:** when UIDs match, the container user will be able to write to mounted files/folders if the host has write permissions to those files.

## Development

To modify the project:

- Update source files in the `./src` directory

- Modify the `./config/install.sh` script if additional build steps are needed

- Update `./config/system-packages.cfg` if additional system packages are required

- Rebuild the project using `./start rebuild`

