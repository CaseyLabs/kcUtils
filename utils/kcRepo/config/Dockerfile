# syntax=docker/dockerfile:1

#| Dockerfile
#| ---
#| Builds a multi-stage Docker image that runs as a non-root user.

ARG KC_CONTAINER_IMAGE=ubuntu:latest

# -- Base Stage

FROM ${KC_CONTAINER_IMAGE} AS base-stage

# Install kc shell helper script
COPY ./config/shell.sh /usr/bin/kc
RUN chmod +x /usr/bin/kc

# Install packages defined in system-packages.cfg
COPY ./config/system-packages.cfg ./system-packages.cfg
RUN <<EOT
  set -e
  kc os upgrade
  kc os install ./system-packages.cfg
  rm -f ./system-packages.cfg
EOT

# -- Build Stage

FROM base-stage AS build-stage

# Create a non-root user
ARG KC_CONTAINER_USER=user
ARG KC_CONTAINER_UID=11001

RUN <<EOT
  set -e
  # Check if a user with the desired UID already exists
  if id -u $KC_CONTAINER_UID >/dev/null 2>&1; then
    echo "User with UID $KC_CONTAINER_UID already exists"
    existing_user=$(id -nu $KC_CONTAINER_UID)
    if [ "$existing_user" != "$KC_CONTAINER_USER" ]; then
      echo "Renaming existing user $existing_user to $KC_CONTAINER_USER"
      usermod -l $KC_CONTAINER_USER $existing_user
      groupmod -n $KC_CONTAINER_USER $existing_user
      usermod -m -d /home/$KC_CONTAINER_USER $KC_CONTAINER_USER
    fi
  else
    echo "Creating new user $KC_CONTAINER_USER with UID $KC_CONTAINER_UID"
    groupadd -g $KC_CONTAINER_UID $KC_CONTAINER_USER
    useradd -m -u $KC_CONTAINER_UID -g $KC_CONTAINER_UID $KC_CONTAINER_USER
    mkdir -p /home/$KC_CONTAINER_USER
  fi
  
  # Ensure home directory exists and has correct ownership
  chown $KC_CONTAINER_UID:$KC_CONTAINER_UID /home/$KC_CONTAINER_USER
EOT

# Copy source code and install script
WORKDIR /home/$KC_CONTAINER_USER

COPY --chown=$KC_CONTAINER_USER:$KC_CONTAINER_USER ./src/* .
COPY --chown=$KC_CONTAINER_USER:$KC_CONTAINER_USER ./config/install.sh .
COPY --chown=$KC_CONTAINER_USER:$KC_CONTAINER_USER ./config/run.sh .

# Install and build source code as non-root user
USER $KC_CONTAINER_USER

RUN <<EOT
  set -e
  sh ./install.sh
  rm -f ./install.sh
EOT

# ---

FROM build-stage AS final-stage

# Run the built source code
CMD ["sh", "./run.sh"]