#!/bin/bash

NGINX_VERSION=1.16.1
NGINX_HASH=f11c2a6dd1d3515736f0324857957db2de98be862461b5a542a3ac6188dbe32b
LIBRESSL_VERSION=2.6.1
LIBRESSL_HASH=c293b3b5f1fc1d6349c019c3905355d577df32734b631d7e656503894e09127e

function verified_curl {
  url="$1"
  file="$2"
  sha256_hash="$3"
  curl --silent --fail --location "$url" >| "$file" \
    && echo "$sha256_hash  $file" | sha256sum -c \
    && tar xf "$file"
}

cd "$(dirname "$0")" || exit 1

verified_curl \
  "http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz" \
  "nginx-$NGINX_VERSION.tar.gz" \
  "$NGINX_HASH"

verified_curl \
  "https://s3-ap-southeast-1.amazonaws.com/loket-infra/public/lib/libressl-$LIBRESSL_VERSION.tar.gz" \
  "libressl-$LIBRESSL_VERSION.tar.gz" \
  "$LIBRESSL_HASH"

cd nginx-$NGINX_VERSION || exit 1

# Patch nginx source
patch -p 0 < "$(dirname "$0")/nginx.patch"

# Configure nginx
./configure \
  --with-cc-opt="-static -static-libgcc" \
  --with-ld-opt="-static" \
  --with-cpu-opt=generic \
  --prefix=/usr/local/nginx \
  --sbin-path=/usr/local/sbin/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --pid-path=/var/run/nginx/nginx.pid \
  --lock-path=/var/lock/nginx.lock \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --http-client-body-temp-path=/var/cache/nginx/client_body_temp \
  --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  --user=www-data \
  --group=www-data \
  --with-http_gzip_static_module \
  --with-http_realip_module \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_v2_module \
  --with-openssl=/usr/local/src/libressl-$LIBRESSL_VERSION \
  --without-http_auth_basic_module \
  --without-http_autoindex_module \
  --without-http_browser_module \
  --without-http_empty_gif_module \
  # #--without-http_fastcgi_module \
  # #--without-http_geo_module \
  # --without-http_map_module \
  # --without-http_memcached_module \
  # --without-http_referer_module \
  # --without-http_scgi_module \
  # --without-http_split_clients_module \
  # --without-http_ssi_module \
  # --without-http_upstream_ip_hash_module \
  # --without-http_upstream_least_conn_module \
  # --without-http_userid_module \
  # --without-http_uwsgi_module \
  # --without-mail_imap_module \
  # --without-mail_pop3_module \
  # --without-mail_smtp_module \
  # --without-select_module

# Install nginx
make install