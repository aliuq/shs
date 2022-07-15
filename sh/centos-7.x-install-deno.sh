#! /bin/bash
set -e
#
# Install deno (https://deno.land)
#
# Used mirrors:
#   deno:       https://x.deno.js.cn/install.sh
#   glibc-2.18: https://ftp.gnu.org/gnu/glibc/glibc-2.18.tar.gz
#
# Usage:
#   $ source <(curl -sL https://raw.githubusercontent.com/aliuq/shs/main/sh/centos-7.x-install-deno.sh)
#

DEFAULT_DENO_URL="https://deno.land/x/install/install.sh"
DEFAULT_GLIBC_2_18_URL="https://ftp.gnu.org/gnu/glibc/glibc-2.18.tar.gz"
if [ -z "$DEFAULT_DENO_URL" ]; then
	DEFAULT_DENO_URL=$DEFAULT_DENO_URL
fi
if [ -z "$GLIBC_2_18_URL" ]; then
	GLIBC_2_18_URL=$DEFAULT_GLIBC_2_18_URL
fi

mirror=''
while [ $# -gt 0 ]; do
  case "$1" in
    --mirror)
      mirror="$2"
      shift
      ;;
    --*)
      echo "Illegal option $1"
      ;;
  esac
  shift $(($# > 0 ? 1 : 0))
done

case "$mirror" in
  Aliyun)
    DENO_URL="https://x.deno.js.cn/install.sh"
    GLIBC_2_18_URL="https://aliuq.oss-cn-beijing.aliyuncs.com/deno/glibc-2.18.tar.gz"
    ;;
esac

ldd=$(ldd --version | grep 'ldd (GNU libc) ' | head -n 1)
lddver=${ldd:15}

function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }

if version_lt $lddver '2.18'; then
  mkdir /temp_down -p && cd /temp_down
  wget "$GLIBC_2_18_URL"
  tar -zxvf glibc-2.18.tar.gz

  cd glibc-2.18 && mkdir build
  cd build
  ../configure --prefix=/usr --disable-profile --enable-add-ons --with-headers=/usr/include --with-binutils=/usr/bin
  make && make install

  cd ~
  rm -rf /temp_down
fi

curl -fsSL "$DENO_URL" | sh

export DENO_INSTALL="/root/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"
