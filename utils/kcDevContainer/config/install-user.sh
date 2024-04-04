#!/bin/sh
set -e

#--- Non-root user package installs

# Setup kcShell helper functions:
kcScriptUrl="https://raw.githubusercontent.com/CaseyLabs/kcUtils/main/utils/kcShell/kcshell.sh"
curl -s ${kcScriptUrl} > ./.kcshell.sh
. ./.kcshell.sh

# Install powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.local/powerlevel10k
