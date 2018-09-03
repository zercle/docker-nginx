# nginx 1.14
FROM	zercle/docker-debian
LABEL	maintainer="Kawin Viriyaprasopsook <bouroo@gmail.com>"

ENV	NGX 1.14.0

# Install nginx
RUN	wget http://nginx.org/keys/nginx_signing.key && apt-key add nginx_signing.key \
	&& echo "deb http://nginx.org/packages/debian/ $(lsb_release -sc) nginx" > /etc/apt/sources.list.d/nginx.list \
	&& echo "deb-src http://nginx.org/packages/debian/ $(lsb_release -sc) nginx" >> /etc/apt/sources.list.d/nginx.list \
	&& apt-get update \
	&& apt-get -y install nginx \
	&& apt-mark hold nginx \
	&& openssl dhparam -dsaparam -out /etc/ssl/dhparam.pem 4096

# Install build tools
RUN	apt-get -y build-dep nginx \
	&& apt-get -y build-dep modsecurity-crs \
	&& apt-get -y install \
		autoconf \
		automake \
		build-essential \
		dpkg-dev \
		ffmpeg \
		frei0r-plugins \
		git \
		libluajit-5.1-dev \
		libcurl4-openssl-dev \
		libpam-dev \
		libpcre3 \
		libpcre3-dev \
		libssl-dev \
		libtool \
		libxml2-dev \
		pkgconf \
	&& apt-get autoclean
		
# Install modsecurity library
RUN	git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity \
	&& cd ModSecurity \
	&& git submodule init \
	&& git submodule update \
	&& ./build.sh \
	&& ./configure \
	&& make \
	&& make install \
	&& rm -rf ../ModSecurity

# Get nginx source
RUN	mkdir -p /tmp/nginx/modules

WORKDIR /tmp/nginx
RUN	wget http://nginx.org/download/nginx-${NGX}.tar.gz \
	&& tar -zxf nginx-${NGX}.tar.gz

WORKDIR /tmp/nginx/modules
RUN	git clone https://github.com/arut/nginx-rtmp-module.git \
	&& git clone https://github.com/tg123/websockify-nginx-module.git \
	&& git clone https://github.com/simplresty/ngx_devel_kit.git \
	&& git clone https://github.com/openresty/lua-nginx-module.git \
	&& git clone https://github.com/SpiderLabs/ModSecurity-nginx

WORKDIR	/tmp/nginx/nginx-1.14.0
RUN	./configure --with-compat \
	--add-dynamic-module=../modules/ngx_devel_kit \
	--add-dynamic-module=../modules/lua-nginx-module \
	--add-dynamic-module=../modules/websockify-nginx-module \
	--add-dynamic-module=../modules/nginx-rtmp-module \
	--add-dynamic-module=../modules/ModSecurity-nginx \
	&& make modules \
	&& mkdir -p /etc/nginx/modules/ \
	&& cp -u objs/*.so /etc/nginx/modules/ \
	&& rm -rf /tmp/nginx

COPY	./files /

VOLUME	["/srv", "/etc/nginx/conf.d"]

WORKDIR	/root

EXPOSE	80 443

CMD	["nginx"]
