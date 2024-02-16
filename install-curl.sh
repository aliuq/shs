#! /bin/sh
set -e
#
# Usage
#    wget -O - https://github.com/aliuq/shs/raw/main/install-curl.sh | sh
#    wget -O - https://github.com/aliuq/shs/raw/main/install-curl.sh | sh -s 8.5.0
#

CURL_VERSION=${1:-8.6.0}

echo "Installing curl version $CURL_VERSION"

apk add --update --no-cache openssl-dev nghttp2-dev ca-certificates libpsl-dev
apk add --update --no-cache --virtual curldeps g++ make perl

wget https://curl.haxx.se/download/curl-$CURL_VERSION.tar.bz2 -O /tmp/curl-$CURL_VERSION.tar.bz2 && \
cd /tmp && \
tar xjvf curl-$CURL_VERSION.tar.bz2 && \
rm curl-$CURL_VERSION.tar.bz2 && \
cd curl-$CURL_VERSION && \
./configure \
  --with-nghttp2=/usr \
  --prefix=/usr \
  --with-ssl \
  --enable-ipv6 \
  --enable-unix-sockets \
  --without-libidn \
  --disable-static \
  --disable-ldap \
  --with-pic && \
make && \
make install && \
cd / && \
rm -rf /tmp/curl-$CURL_VERSION && \
apk del curldeps
