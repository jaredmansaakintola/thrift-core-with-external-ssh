FROM ubuntu:16.04
ENV THRIFT_VERSION 0.9.3
ARG DEBIAN_FRONTEND=noninteractive
#ARG REPO
ARG THRIFT_ENTRYPOINT
ARG REQ
COPY ./rpc-service /rpc

# install ssh
RUN  apt-get -yq update && \
     apt-get -yqq install ssh

# add bitbucket credentials on build
# NOTE ensure that you have your ssh keys generated on host machine and that they have been added to revision control 
ARG SSH_PRIVATE_KEY
ARG SSH_PUBLIC_KEY
RUN mkdir /root/.ssh/
RUN echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa && \
    echo "${SSH_PUBLIC_KEY}" > /root/.ssh/id_rsa.pub && \
    chmod 400 /root/.ssh/id_rsa && \
    chmod 400 /root/.ssh/id_rsa.pub

# make sure your domain is accepted
RUN touch /root/.ssh/known_hosts
RUN ssh-keyscan bitbucket.org >> /root/.ssh/known_hosts

# BASIC INSTALLS
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    curl \
    wget \
    vim \
    make

# PYTHON INSTALL
RUN apt-get install build-essential checkinstall -y \
    && apt-get install libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev -y \
    && cd /usr/src \
    && wget https://www.python.org/ftp/python/2.7.12/Python-2.7.12.tgz \
    && tar xzf Python-2.7.12.tgz \
    && cd Python-2.7.12 \
    && ./configure --enable-optimizations \
    && make altinstall

# THRIFT INSTALL
RUN buildDeps=" \
		automake \
		bison \
		curl \
		flex \
		g++ \
		libboost-dev \
		libboost-filesystem-dev \
		libboost-program-options-dev \
		libboost-system-dev \
		libboost-test-dev \
		libevent-dev \
		libssl-dev \
		libtool \
		make \
		pkg-config \
	"; \
	apt-get update && apt-get install -y --no-install-recommends $buildDeps && rm -rf /var/lib/apt/lists/* \
	&& curl -sSL "http://apache.mirrors.spacedump.net/thrift/$THRIFT_VERSION/thrift-$THRIFT_VERSION.tar.gz" -o thrift.tar.gz \
	&& mkdir -p /usr/src/thrift \
	&& tar zxf thrift.tar.gz -C /usr/src/thrift --strip-components=1 \
	&& rm thrift.tar.gz \
	&& cd /usr/src/thrift \
	&& ./configure  --without-python --without-cpp \
	&& make \
	&& make install \
	&& cd / \
	&& rm -rf /usr/src/thrift \
	&& curl -k -sSL "https://storage.googleapis.com/golang/go1.4.linux-amd64.tar.gz" -o go.tar.gz \
	&& tar xzf go.tar.gz \
	&& rm go.tar.gz \
	&& cp go/bin/gofmt /usr/bin/gofmt \
	&& rm -rf go \
	&& apt-get purge -y --auto-remove $buildDeps

RUN apt-get update && \
    apt-get install -y software-properties-common python-software-properties 

RUN apt-get update && \
    apt-get install -y php7.0-cli php7.0-mbstring git unzip

RUN apt-get update && apt-get install -y python-pip 
RUN apt-get install -y curl && \
    curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer

WORKDIR /rpc
#RUN composer install

#CMD [ "thrift", "-version" ]
ENV COMPOSER_ALLOW_SUPERUSER 1
CMD composer install && /usr/local/bin/python2.7  api/rpc.py 
EXPOSE 1337
