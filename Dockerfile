FROM hypriot/rpi-alpine as builder

ENV KONG_VERSION 1.1.0rc1
ENV KONG_SHA256 72abd186181b5ebb263c4e12db5d89cac529e2b5ca858015d44a34d560755b35
ENV OPENSSL_VERSION 1.0.2h
ENV OPENRESTY_VERSION 1.13.6.2

RUN apk add --update alpine-sdk

RUN apk add --no-cache --virtual .build-deps wget tar ca-certificates \
	&& apk add --no-cache libgcc openssl pcre perl tzdata curl libcap su-exec unzip zlib-dev 

RUN wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.40.tar.gz \
	&& tar -xvf pcre-8.40.tar.gz

RUN wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
	&& tar -zvxf openssl-${OPENSSL_VERSION}.tar.gz \
	&& wget https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-${OPENSSL_VERSION}-sess_set_get_cb_yield.patch \
	&& cd openssl-${OPENSSL_VERSION}/ \
	&& patch -p1 < ../openssl-${OPENSSL_VERSION}-sess_set_get_cb_yield.patch \
	&& ./config -fPIC \
	&& make \
	&& make test \
	&& make install \
	&& cd ..

RUN wget https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz \
	&& tar -zxvf openresty-${OPENRESTY_VERSION}.tar.gz


RUN	wget -O kong.tar.gz "https://bintray.com/kong/kong-community-edition-alpine-tar/download_file?file_path=kong-community-edition-$KONG_VERSION.apk.tar.gz" \
	&& wget -O wget -O openresty.tar.gz https://openresty.org/download/openresty-1.13.6.2.tar.gz

RUN	mkdir /tmp/openresty \
	&& tar -xzf /openresty.tar.gz \
	&& cd openresty-${OPENRESTY_VERSION} \
	&& ./configure --with-pcre=../pcre-8.40 --with-openssl=../openssl-1.0.2h -j2 --with-pcre-jit  --with-http_ssl_module --with-http_realip_module   --with-http_stub_status_module  --with-http_v2_module \
	&& make -j2 \
	&& sudo make install \
	&& export PATH="$PATH:/usr/local/openresty/bin"


RUN wget -O luarocks.tar.gz http://luarocks.github.io/luarocks/releases/luarocks-2.4.3.tar.gz \
	&& tar -xzf luarocks.tar.gz \
	&& cd luarocks-2.4.3 \
	&& ./configure --lua-suffix=jit --with-lua=/usr/local/openresty/luajit --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1  \
	&& make build \
	&& make install \
	&& cd ..

RUN apk add --no-cache bsd-compat-headers m4

RUN luarocks install kong 1.0.3-0 OPENSSL_DIR=/usr/local/ssl CRYPTO_DIR=/usr/local/ssl

RUN cd /tmp \
	&& tar xvf /kong.tar.gz \
	&& cp /tmp/usr/local/bin/kong /usr/local/openresty/bin \
	&& ln -s /usr/local/openresty/bin/kong /usr/local/bin/kong \
	&& cp -a /tmp/usr/local/kong /usr/local

RUN kong roar


FROM hypriot/rpi-alpine
LABEL maintainer="Sven Walther <sven@walther.world>"

COPY --from=builder /usr/local /usr/local

RUN adduser -Su 1337 -g root kong \
 	&& apk add --no-cache --virtual .build-deps wget tar ca-certificates \
 	&& apk add --no-cache libgcc openssl pcre perl tzdata curl libcap su-exec

RUN	mkdir /tmp/openresty \
 	&& apk del .build-deps \
 	&& chown -R kong /usr/local/kong \
    && chgrp -R 0 /usr/local/kong \
    && chmod -R g=u /usr/local/kong


COPY docker-entrypoint.sh /docker-entrypoint.sh
USER kong

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 8444

STOPSIGNAL SIGTERM

CMD ["kong", "docker-start"]
