#!/bin/sh

#| # kcShell
#| A collection of POSIX-compatible shell helper functions, designed to simplify shell script writing.
#|
#| ## Install  
#|   
#| ```sh
#| kcScriptUrl="https://raw.githubusercontent.com/CaseyLabs/kcUtils/main/utils/kcShell/kcshell.sh"
#| curl -s ${kcScriptUrl} > kc
#| chmod +x kc
#| sudo cp kc /usr/local/bin/
#| ```    
#|   
#| ## Usage  
#| `kc [command] [args]`  
#|   

# -- Vars

# Detect the OS and architecture
kcShell=${0##*/}
kcOS=$(grep '^ID=' /etc/os-release | cut -f2 -d'=' 2>/dev/null || uname)
kcOSLIKE=$(grep '^ID_LIKE=' /etc/os-release | cut -f2 -d'=' 2>/dev/null || uname)
kcArch=$(uname -m)

# Check if we are root
if [ "$(id -u)" -ne 0 ]; then
  sudo_cmd=sudo
else
  sudo_cmd=""
fi

#| ## Available Functions

kc_log() {
  #| ### `kc log`
  #| Simple logging function that logs messages to stdout/stderr.
  #| Usage: `kc log [event type] [event message]`
  #| Example: 
  #| ```
  #| > kc log info "This is an info message"
  #| 2024-09-20T10:25:36Z | laptop | [info] This is an info message
  #| 
  #| > kc log error "This is an error message that goes to stderr"
  #| 2024-09-20T10:25:36Z | laptop | [error] This is an error message that goes to stderr
  #| ```
  
  if [ $# -ne 2 ]; then
    echo "Simple shell logging function."
    echo "Usage: kc log [event type] [event message]"
    echo "kc log error \"This is an error message that goes to stderr\""
    return 1
  fi

  timestamp=$(date +"%Y-%m-%dT%H:%M:%SZ")
  eventType=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  eventMessage="$2"

  logPrefix="$timestamp | $HOSTNAME | [$eventType]"

  case "$eventType" in
    debug)
      [ -z "$DEBUG" ] && return
      echo "$logPrefix $eventMessage"
      ;;
    error)
      echo "$logPrefix $eventMessage" >&2
      ;;
    info|warning)
      echo "$logPrefix $eventMessage"
      ;;
    *)
      echo "$logPrefix Unknown event type: $eventType - $eventMessage"
      ;;
  esac
}

kc_check() {
  #| ### `kc check`
  #| Checks if a file, folder, command, or variable exists.
  #| Usage: kc check [file/folder/command/variable]
  #| Examples:
  #| - `kc check /path/to/file`
  #| - `kc check /path/to/folder`
  #| - `kc check commandName`
  #| - `kc check variableName`
  #|
  #| ```
  #| > kc check UID
  #| Shell var exists: UID
  #|
  #| > kc check pwd
  #| Command exists: pwd
  #| ```
  if [ $# -ne 1 ]; then
    echo "Checks if a file, folder, command, or variable exists."
    echo "Usage: kc check [file/folder/command/variable]"
    echo "Example: kc check /path/to/file"
    return 1
  fi

  if [ -e "$1" ]; then
    printf "File or folder exists: %s\n" "$1"
  elif command -v "$1" >/dev/null 2>&1; then
    printf "Command exists: %s\n" "$1"
  elif [ -n "$(printenv $1)" ]; then
    printf "Env var exists: %s\n" "$1"
  else
    case "$1" in
      "UID") 
        if [ -n "$UID" ]; then
          printf "Shell var exists: %s\n" "$1"
        else
          printf "Could not find: %s\n" "$1"
          return 1
        fi
        ;;
      *)
        printf "Could not find: %s\n" "$1"
        return 1
        ;;
    esac
  fi
}

kc_os() {
  #| ### `kc os`
  #| Commands for Linux system package managers, such as apt, yum, pacman, apk
  #| Usage: `kc os [update/upgrade/install/remove/clean/info]`
  #| ```
  #| kc os install curl
  #| kc os remove wget
  #| kc os upgrade # upgrade all system packages
  #| ```

  if [ -z "$1" ]; then
    echo "Commands for Linux system package managers, such as apt, yum, pacman, apk"
    echo "Usage: kc os [update/upgrade/install/remove/clean/info]"
    echo "Example: kc os install curl" 
    echo "Example: kc os remove wget"
    return 1
  fi

  case "${kcOS}|${kcOSLIKE}" in
    *ubuntu*|*debian*)
      export DEBIAN_FRONTEND=noninteractive
      update_cmd="apt-get update"
      install_cmd="apt-get install -y"
      remove_cmd="apt-get remove -y"
      upgrade_cmd="apt-get upgrade -y"
      clean_cmd="apt-get clean; apt-get autoremove -y"
      ;;
    *centos*|*rhel*|*fedora*|*amazon*)
      install_cmd="yum install -y"
      remove_cmd="yum remove -y"
      upgrade_cmd="yum upgrade -y"
      clean_cmd="yum clean all"
      ;;
    *alpine*)
      install_cmd="apk add"
      remove_cmd="apk del"
      upgrade_cmd="apk upgrade"
      clean_cmd="apk cache clean"
      ;;
    *arch*|*manjaro*)
      install_cmd="pacman -S --noconfirm"
      remove_cmd="pacman -R --noconfirm"
      upgrade_cmd="pacman -Syu --noconfirm"
      clean_cmd="pacman -Sc --noconfirm"
      ;;
    *)
      printf "Unsupported operating system: %s\n" "$kcOS"
      return 1
      ;;
  esac

  case "$1" in
    update)
      $sudo_cmd $update_cmd
      ;;
    upgrade)
      $sudo_cmd $upgrade_cmd
      ;;
    install)
      shift
      if [ "$#" -eq 0 ]; then
        echo "Usage: kc os install [package...]"
        return 1
      fi
      $sudo_cmd $install_cmd "$@"
      ;;
    remove)
      shift
      if [ "$#" -eq 0 ]; then
        echo "Usage: kc os remove [package...]"
        return 1
      fi
      $sudo_cmd $remove_cmd "$@"
      ;;
    clean)
      $sudo_cmd $clean_cmd
      ;;
    info)
      printf "Operating System: kcOS = %s\n" "$kcOS"
      printf "Architecture: kcArch = %s\n" "$kcArch"
      printf "OS Like: kcOSLIKE = %s\n" "$kcOSLIKE"
      ;;
    help)
      kc_help "os"
      ;;
    *)
      printf "Unknown command: %s\n" "$1"
      return 1
      ;;
  esac 
}

kc_edit() {
  #| ### `kc edit`
  #| Edits a file (with sudo automatically if neeeded) and saves a backup 
  #| (Default backup retention: 5)
  #| Usage: `kc edit /path/to/file`
  backup_limit=5

  if [ $# -eq 0 ]; then
    echo "Edits a file (saves backup to /path/.kcbackup)"
    echo "Usage: kc edit /path/to/file" >&2
    return 1
  fi

  abs_path=$(realpath "$1" 2>/dev/null || { cd "$(dirname "$1")" && pwd -P; echo "$(basename "$1")"; })

  if [ ! -r "$abs_path" ] && ! $sudo_cmd test -r "$abs_path"; then
    echo "File does not exist or is not readable: $abs_path" >&2
    return 1
  fi

  backup_dir="${abs_path%/*}/.kc_backups"
  run_with_sudo() {
    if $sudo_cmd -n true 2>/dev/null; then
      $sudo_cmd "$@"
    else
      "$@"
    fi
  }

  # Ensure backup directory exists
  [ ! -d "$backup_dir" ] && run_with_sudo mkdir -p "$backup_dir"

  # Create a temporary backup before editing
  temp_backup="$backup_dir/$(basename "$abs_path").temp"
  run_with_sudo cp -a "$abs_path" "$temp_backup"

  # Edit file
  editor="${EDITOR:-$(command -v nano || command -v vi)}"
  if ! run_with_sudo "$editor" "$abs_path"; then
    echo "Failed to edit file: $abs_path" >&2
    return 1
  fi

  # Check if the file has changed and move the temp backup if so
  if ! cmp -s "$abs_path" "$temp_backup"; then
    timestamp=$(date +%s)
    backup_file="$backup_dir/$(basename "$abs_path").$timestamp"
    run_with_sudo mv "$temp_backup" "$backup_file" && echo "Backup created: $backup_file"
  else
    run_with_sudo rm "$temp_backup"  # Remove temp backup if no changes
  fi

  # Cleanup old backups
  find "$backup_dir" -name "$(basename "$abs_path").*" -type f | sort -r | tail -n +$((backup_limit+1)) | xargs -r run_with_sudo rm
}


kc_help() {
  #| ### `kc help`
  #| Displays this help text.
  if [ -n "$1" ]; then
    if command -v "kc_$1" >/dev/null 2>&1; then
      printf "Help for 'kc %s':\n\n" "$1"
      grep -A 10 "kc_$1()" "$0" | grep -E '^#\| ' | sed -E 's/^#\| //'
    else
      printf "[kc] No help available for '%s'.\n" "$1"
    fi
  else
    echo "kcShell - POSIX-compatible shell script helper functions"
    echo
    echo "Usage: kc [command] [args]"
    echo
    echo "Available commands:"
    grep -E '^\s*kc_[a-zA-Z_]+\(\)\s*{' "$0" | sed -E 's/kc_([a-zA-Z_]+)\(\).*/\1/' | while read -r cmd; do
      echo "  $cmd"
    done
    echo
    echo "Run 'kc [command]' for more details on each command."
  fi
}

# --- Run the function

if command -v "kc_$1" >/dev/null 2>&1; then
  command="kc_$1"
  shift
  if [ "$1" = "help" ]; then
    kc_help "$command"
  else
    $command "$@"
  fi
else
  if [ "$1" = "help" ]; then
    shift
    kc_help "$1"
  else
    printf "[kc] Unknown option. Run \"kc help\" for available options.\n"
    exit 1
  fi
fi

#| ## Demo  
#| ![Image of kcShell running](./demo.gif)  
