# `kcRepo`

A flexible, container-driven git repository template for new projects.

### Features

- Drop your source code into `./src`
- Edit and update `./config/settings.cfg` and `./config/Dockerfile`
- Run `./start run` in a Terminal
- Your app will be built and running in a container!

## Demo

![Image of kcRepo running](./demo.gif)

## Project Structure

```
.
├── config                      # Config files used during container build
│   ├── docker-compose.yml
│   ├── Dockerfile              
│   └── settings.cfg     
│
├── src                         # Source code
│
└── start                    # Repo Start script (Usage: ./start)
```

## Usage

### Suggested first-run command 

`./start run`

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