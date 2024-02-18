#!/bin/sh

# Usage
#
#  >  curl -fsSL https://raw.githubusercontent.com/aliuq/shs/main/zsh/ubuntu.sh | sh
#  >  curl -fsSL https://raw.githubusercontent.com/aliuq/shs/main/zsh/ubuntu.sh | sh -s 5.9
#  >  ZSH_ORIGIN=https://udomain.dl.sourceforge.net curl -fsSL https://raw.githubusercontent.com/aliuq/shs/main/zsh/ubuntu.sh | sh -s 5.9
#
ZSH_VERSION=${1:-5.9}
ZSH_ORIGIN=${ZSH_ORIGIN:-"https://zenlayer.dl.sourceforge.net"}

echo """
  Installing zsh version $ZSH_VERSION on $ZSH_ORIGIN

  OS: Ubuntu
  Requireed: curl make gcc libncurses5-dev libncursesw5-dev

  Run the following commands to install required deps:

    apt install -y curl make gcc libncurses5-dev libncursesw5-dev
"""

command_exists() {
  command -v "$@" >/dev/null 2>&1
}

check_commands() {
  for cmd in "$@"; do
    if ! command_exists "$cmd"; then
      echo "Error: $cmd is not installed or not in PATH" >&2
      exit 1
    fi
  done
}

install_zsh() {
  curl -fsS -o /tmp/zsh.tar.xz $ZSH_ORIGIN/project/zsh/zsh/$ZSH_VERSION/zsh-$ZSH_VERSION.tar.xz && \
  tar -xf /tmp/zsh.tar.xz -C /tmp && \
  cd /tmp/zsh-$ZSH_VERSION && \
  ./Util/preconfig && \
  ./configure --without-tcsetpgrp --prefix=/usr --bindir=/bin && \ 
  make -j 20 install.bin install.modules install.fns && \
  cd / && rm -rf /tmp/zsh.tar.xz && rm -rf /tmp/zsh-$ZSH_VERSION && \
  zsh --version && \
  echo "/bin/zsh" | tee -a /etc/shells && \
  echo "/usr/bin/zsh" | tee -a /etc/shells
}

check_commands curl tar make gcc
install_zsh
