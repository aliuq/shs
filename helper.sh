#! /bin/sh

# Usage:
#
# For shell:
#
# . /dev/stdin <<EOF
# $(curl -sSL https://raw.githubusercontent.com/aliuq/shs/main/helper.sh)
# EOF
#
# . /dev/stdin <<EOF
# $(wget -qO- https://github.com/aliuq/shs/raw/main/helper.sh)
# EOF

# For bash:
#
# source <(curl -sSL https://raw.githubusercontent.com/aliuq/shs/main/helper.sh)
# source <(wget -qO- https://raw.githubusercontent.com/aliuq/shs/main/helper.sh)
#
# Another short link:
#
# + https://s.xod.cc/shell-helper
# + https://bit.ly/shell-helper
#
# Another short mirror link:
#
# + https://s.xod.cc/shell-helper-mirror
# + https://bit.ly/shell-helper-mirror

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

log() {
  printf "${cyan}[INFO] $(date "+%Y-%m-%d %H:%M:%S")${plain} $1\n"
}
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

# 获取年月日时分秒格式的时间
get_date() {
  date '+%Y年%m月%d日 %H时%M分%S秒'
}

# 发送 Webhook 消息
send_webhook() {
  # 如果不存在 MY_WEBHOOK_URL 环境变量，则不发送消息
  if [ -z "$MY_WEBHOOK_URL" ]; then
    return
  fi

  # 如果不存在消息内容，则不发送消息
  if [ -z "$1" ]; then
    return
  fi

  local content="$1"
  body="{\"content\":\"$content\"}"
  run "curl -X POST -H 'Content-Type: application/json' -d '$body' \"$MY_WEBHOOK_URL\""
}

set_var
