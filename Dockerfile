FROM debian:buster-slim as Buildstage

# Install dependencies and packages
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install --no-install-recommends \
        build-essential \
        ca-certificates \
        check \
        cmake \
        cython3 \
        git \
        libcap2-bin \
        libcurl4-openssl-dev \
        libemu-dev \
        libev-dev \
        libglib2.0-dev \
        libloudmouth1-dev \
        libnetfilter-queue-dev \
        libnl-3-dev \
        libpcap-dev \
        libssl-dev \
        libtool \
        libudns-dev \
        procps \
        python3 \
        python3-dev \
        python3-bson \
        python3-yaml &&\
    # Get and install dionaea
    git clone --depth=1 https://github.com/dinotools/dionaea -b 0.8.0 /tmp/dionaea/ && \
    cd /tmp/dionaea && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/opt/dionaea .. && \
    make && \
    make install

FROM alpine:latest

# Include dist
ADD dist/ /root/dist/

# Copy Dionaea from Buildstage
COPY --from=Buildstage /opt/dionaea /opt/dionaea

# Setup user and groups
RUN apk add --no-cache --update-cache \
      ca-certificates \
      python3 \
      py3-bson \
      pyt3-yaml \
      libcurl \
      libx86emu \
      libev \
      glib \
      libnetfilter_queue \
      libnl3\
      libpcap \
      udns && \
    # Setup user, groups and config
    addgroup --gid 2000 dionaea && \
    adduser --system --no-create-home --shell /bin/bash --uid 2000 --disabled-password --disabled-login --gid 2000 dionaea && \
    setcap cap_net_bind_service=+ep /opt/dionaea/bin/dionaea && \
    # Supply configs and set permissions
    chown -R dionaea:dionaea /opt/dionaea && \
    rm -rf /opt/dionaea/etc/dionaea/* && \
    mv /root/dist/etc/* /opt/dionaea/etc/dionaea/ && \
    # Clean up
    rm -rf /root/* /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set workdir, stopsignal and start dionaea
STOPSIGNAL SIGKILL
USER dionaea:dionaea
WORKDIR /opt/dionaea/bin
CMD dionaea -u dionaea -g dionaea -c /opt/dionaea/etc/dionaea/dionaea.cfg
