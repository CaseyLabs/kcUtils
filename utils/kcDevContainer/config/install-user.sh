#!/bin/sh
set -e

#--- Non-root user package installs

# Install powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.local/powerlevel10k
