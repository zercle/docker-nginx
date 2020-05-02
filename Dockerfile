# nginx 1.18.0
FROM	zercle/docker-debian
LABEL	maintainer="Kawin Viriyaprasopsook <bouroo@gmail.com>"

ENV	NGX 1.18.0

# Install nginx
RUN	wget http://nginx.org/keys/nginx_signing.key && apt-key add nginx_signing.key \
	&& echo "deb http://nginx.org/packages/debian/ $(lsb_release -sc) nginx" > /etc/apt/sources.list.d/nginx.list \
	&& echo "deb-src http://nginx.org/packages/debian/ $(lsb_release -sc) nginx" >> /etc/apt/sources.list.d/nginx.list \
	&& apt-get update \
	&& apt-get dist-upgrade -y \
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
		git \
		libcurl4-openssl-dev \
		libgeoip-dev \
		liblmdb-dev \
		libpcre++-dev \
		libssl-dev \
		libtool \
		libxml2-dev \
		libyajl-dev \
		zlib1g-dev \
		pkgconf \
	&& apt-get autoclean
		
# Install modsecurity library
RUN	cd /tmp && \
	git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity \
	&& cd /tmp/ModSecurity \
	&& git submodule init \
	&& git submodule update \
	&& ./build.sh \
	&& ./configure \
	&& make \
	&& make install \
	&& rm -rf /tmp/ModSecurity

# Get nginx source
RUN	mkdir -p /tmp/nginx/modules \
	&& cd /tmp/nginx \
	&& wget http://nginx.org/download/nginx-${NGX}.tar.gz \
	&& tar -zxf nginx-${NGX}.tar.gz \
	&& cd /tmp/nginx/modules \
	&& git clone https://github.com/SpiderLabs/ModSecurity-nginx \
	&& cd /tmp/nginx/nginx-${NGX} \
	&& ./configure --with-compat \
	--add-dynamic-module=../modules/ModSecurity-nginx \
	&& make modules \
	&& mkdir -p /etc/nginx/modules/ \
	&& cp -u objs/*.so /etc/nginx/modules/ \
	&& rm -rf /tmp/nginx \
	&& mkdir -p /etc/nginx/modsec \
	&& wget -O /etc/nginx/modsec/modsecurity.conf https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended \
	&& wget -O /etc/nginx/modsec/unicode.mapping https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping \
	&& rm -rf /tmp/*

COPY	./files /

VOLUME	["/srv", "/etc/nginx/conf.d"]

WORKDIR	/root

EXPOSE	80 443

CMD	["nginx", "-g", "daemon off;"]
