#! /bin/bash
set -e
#
# Copy public key to remote host, and update ssh configuration `PubkeyAuthentication` to `yes`
#
# Usage:
#   cat "<User> X.X.X.X <Password>" | sh https://raw.githubusercontent.com/aliuq/shs/main/sh/sshpass.sh --name test_rsa
#

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

name="id_rsa"
while [ $# -gt 0 ]; do
  case "$1" in
    --name)
      name="$2"
      shift
      ;;
    --*)
      echo "Illegal option $1"
      ;;
  esac
  shift $(($# > 0 ? 1 : 0))
done

command_exists() {
  command -v "$@" > /dev/null 2>&1
}

do_run() {
  if ! command_exists sshpass; then
    yum install sshpass -y
  fi

  secrect="$HOME/.ssh/$name"
  if [ -a "$secrect" ]; then
    echo -e "${red}ERROR: ssh key $name is already exists at $secrect${plain}"
    echo
  else
    ssh-keygen -t rsa -f $secrect -N "" -q
  fi

  while read user ip passwd
  do
    sleep 1
    sshpass -p $passwd ssh-copy-id -i $secrect.pub $user@$ip
    sleep 1
    sshpass -p $passwd ssh $user@$ip 'sed -i "s/^#\?PubkeyAuthentication \(yes\|no\)$/PubkeyAuthentication yes/g" /etc/ssh/sshd_config && systemctl restart sshd'
    echo
    echo -e "   ${green}ssh -i $secrect $user@$ip${plain}"
    echo
  done
}
do_run
