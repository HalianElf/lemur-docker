# CFSSL Build
FROM golang:1.13.6-alpine3.10 as cf-builder

WORKDIR /workdir
COPY cfssl/ /workdir

RUN set -x && \
	apk --no-cache add git gcc libc-dev make

RUN git clone https://github.com/cloudflare/cfssl_trust.git /etc/cfssl && \
    make clean && \
    make bin/rice && ./bin/rice embed-go -i=./cli/serve && \
    make all

# Lemur Build
FROM organizrtools/base-alpine

ARG VIRTUAL_ENV="false"
ENV LEMUR_VERSION="master" \
    LEMUR_TARGET="develop" \
    PGCONF="/config" \
    PGDATA="/data"

RUN \
    echo "**** install build packages ****" && \
    apk add --no-cache --virtual=build-dependencies --upgrade \
        git \
        make \
        autoconf \
        automake \
        nasm \
        build-base \
        python3-dev \
        zlib-dev \
        libffi-dev \
        postgresql-dev \
        openldap-dev \
        nodejs \
        npm && \
    echo "**** install runtime packages ****" && \
    apk add --no-cache --upgrade \
        bash \
        python3 \
        postgresql \
        postgresql-contrib \
        openssl \
        nginx && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --no-cache --upgrade setuptools wheel && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    echo "**** fetch and install lemur ****" && \
    git clone https://github.com/netflix/lemur.git /app && \
    cd /app && \
    git checkout ${LEMUR_VERSION} && \
    make ${LEMUR_TARGET} && \
    npm install --unsafe-perm && node_modules/.bin/gulp build && \
    node_modules/.bin/gulp package && \
    rm -r bower_components node_modules && \
    echo "**** cleanup ****" && \
    apk del --purge \
        build-dependencies && \
    rm -rf /tmp/* /app/docker /app/docs /app/AUTHORS /app/CHANGELOG.rst /app/Dockerfile /app/LICENSE \
        /app/OSSMETADATA /app/README.rst /app/docker-compose.yml

# copy cfssl files
COPY --from=cf-builder /etc/cfssl /etc/cfssl
COPY --from=cf-builder /workdir/bin/ /usr/bin

# add local files
COPY root/ /