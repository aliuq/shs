#! /bin/sh

# Usage:
#
#  > source <(curl -sSL https://github.com/aliuq/shs/raw/main/helper.sh)
#  > source <(wget -qO- https://github.com/aliuq/shs/raw/main/helper.sh)
#

# Colors
bold="\033[1m"
red="\033[0;31m"
green="\033[0;32m"
yellow="\033[0;33m"
cyan="\033[0;36m"
plain="\033[0m"

verbose=false
force=false
help=false
dry_run=false

for arg in "$@"; do
  case "$arg" in
    --verbose)
      verbose=true
      ;;
    -v)
      verbose=true
      ;;
    --force)
      force=true
      ;;
    -y)
      force=true
      ;;
    --dry-run)
      dry_run=true
      ;;
    --help)
      help=true
      ;;
  esac
done


info() {
  printf "$1\n"
}
yellow() {
  printf "${yellow}$1${plain}\n"
}
green() {
  printf "${green}$1${plain}\n"
}
red() {
  printf "${red}$1${plain}\n"
}
cyan() {
  printf "${cyan}$1${plain}\n"
}

command_exists() {
  command -v "$@" >/dev/null 2>&1
}

command_valid() {
  if ! command_exists "$1"; then
    if [ -z "$2" ]; then
      red "Error: $1 is not installed"
    else
      red "$2"
    fi
    exit 1
  fi
}

run() {
  if $dry_run; then
    echo "+ $sh_c '$1'"
    return
  fi
  if $verbose; then
    echo "+ $sh_c '$1'"
  fi
  $sh_c "$1"
}

set_var() {
  user="$(id -un 2>/dev/null || true)"
  sh_c="sh -c"
  if [ "$user" != "root" ]; then
    if command_exists sudo; then
      sh_c="sudo -E sh -c"
    elif command_exists su; then
      sh_c="su -c"
    else
      cat >&2 <<-EOF
			Error: this installer needs the ability to run commands as root.
			We are unable to find either "sudo" or "su" available to make this happen.
			EOF
      exit 1
    fi
  fi
}

set_var
