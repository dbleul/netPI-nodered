
#use armv7hf compatible base image
FROM balenalib/armv7hf-debian:buster-20191223

#dynamic build arguments coming from the /hooks/build file
ARG BUILD_DATE
ARG VCS_REF

#ARG FIELDBUS_NODE=netPI-nodered-fieldbus
#ARG FIELDBUS_NODE_VERSION=1.0.5
#ARG FIELDBUS_NODE_DIR=/tmp/${FIELDBUS_NODE}-${FIELDBUS_NODE_VERSION}

#ARG FRAM_NODE=netPI-nodered-fram
#ARG FRAM_NODE_VERSION=1.1.0
#ARG FRAM_NODE_DIR=/tmp/${FRAM_NODE}-${FRAM_NODE_VERSION}

#ARG USER_LEDS_NODE=netPI-nodered-user-leds
#ARG USER_LEDS_NODE_VERSION=1.0.0
#ARG USER_LEDS_NODE_DIR=/tmp/${USER_LEDS_NODE}-${USER_LEDS_NODE_VERSION}

#ARG NPIX_LEDS_NODE=netPI-nodered-npix-leds
#ARG NPIX_LEDS_NODE_VERSION=0.9.3
#ARG NPIX_LEDS_NODE_DIR=/tmp/${NPIX_LEDS_NODE}-${NPIX_LEDS_NODE_VERSION}

#ARG NPIX_AI_NODE=netPI-nodered-npix-ai
#ARG NPIX_AI_NODE_VERSION=1.0.3
#ARG NPIX_AI_NODE_DIR=/tmp/${NPIX_AI_NODE}-${NPIX_AI_NODE_VERSION}

#ARG NPIX_IO_NODE=netPI-nodered-npix-io
#ARG NPIX_IO_NODE_VERSION=1.0.2
#ARG NPIX_IO_NODE_DIR=/tmp/${NPIX_IO_NODE}-${NPIX_IO_NODE_VERSION}

#ARG NODE-RED_VERSION=1.0.3

#ARG NODEJS_VERSION=12.x

#metadata labels
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/HilscherAutomation/netPI-netx-ethernet-lan" \
      org.label-schema.vcs-ref=$VCS_REF

#enable building ARM container on x86 machinery on the web (comment out next line if not built as automated build on docker hub)
RUN [ "cross-build-start" ]

#version
ENV HILSCHERNETPI_NETX_TCPIP_NETWORK_INTERFACE_VERSION 1.1.0

#labeling
LABEL maintainer="netpi@hilscher.com" \
      version=$HILSCHERNETPI_NETX_TCPIP_NETWORK_INTERFACE_VERSION \
      description="netX based TCP/IP network interface"

#copy files
COPY "./init.d/*" /etc/init.d/
COPY "./driver/*" "./driver/includes/" "./firmware/*" /tmp/

#do installation
RUN apt-get update  \
    && apt-get install -y openssh-server build-essential ifupdown isc-dhcp-client \
#do users root and pi
    && useradd --create-home --shell /bin/bash pi \
    && echo 'root:root' | chpasswd \
    && echo 'pi:raspberry' | chpasswd \
    && adduser pi sudo \
    && mkdir /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
#install netX driver and netX ethernet supporting firmware
    && dpkg -i /tmp/netx-docker-pi-drv-2.0.1-r0.deb \
    && dpkg -i /tmp/netx-docker-pi-pns-eth-3.12.0.8.deb \
#compile netX network daemon that creates the cifx0 ethernet interface
    && echo "Irq=/sys/class/gpio/gpio24/value" >> /opt/cifx/plugins/netx-spm/config0 \
    && cp /tmp/*.h /usr/include/cifx \
    && cp /tmp/cifx0daemon.c /opt/cifx/cifx0daemon.c \
    && gcc /opt/cifx/cifx0daemon.c -o /opt/cifx/cifx0daemon -I/usr/include/cifx -Iincludes/ -lcifx -pthread \
#clean up
    && rm -rf /tmp/* \
    && apt-get remove build-essential \
    && apt-get -yqq autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*

#RUN curl https://codeload.github.com/HilscherAutomation/${FIELDBUS_NODE}/tar.gz/${FIELDBUS_NODE_VERSION} -o /tmp/${FIELDBUS_NODE} \
# && curl https://codeload.github.com/HilscherAutomation/${FRAM_NODE}/tar.gz/${FRAM_NODE_VERSION} -o /tmp/${FRAM_NODE} \
# && curl https://codeload.github.com/HilscherAutomation/${USER_LEDS_NODE}/tar.gz/${USER_LEDS_NODE_VERSION} -o /tmp/${USER_LEDS_NODE} \
# && curl https://codeload.github.com/HilscherAutomation/${NPIX_LEDS_NODE}/tar.gz/${NPIX_LEDS_NODE_VERSION} -o /tmp/${NPIX_LEDS_NODE} \
# && curl https://codeload.github.com/HilscherAutomation/${NPIX_AI_NODE}/tar.gz/${NPIX_AI_NODE_VERSION} -o /tmp/${NPIX_AI_NODE} \
# && curl https://codeload.github.com/HilscherAutomation/${NPIX_IO_NODE}/tar.gz/${NPIX_IO_NODE_VERSION} -o /tmp/${NPIX_IO_NODE} \
# && tar -xvf /tmp/${FIELDBUS_NODE} -C /tmp/ \
# && tar -xvf /tmp/${FRAM_NODE} -C /tmp/ \
# && tar -xvf /tmp/${USER_LEDS_NODE} -C /tmp/ \
# && tar -xvf /tmp/${NPIX_AI_NODE} -C /tmp/ \
# && tar -xvf /tmp/${NPIX_IO_NODE} -C /tmp/ \
# && tar -xvf /tmp/${NPIX_LEDS_NODE} -C /tmp/ \
# -------------------- Install nodejs and Node-RED --------------------------------------
#install node.js V8.x.x and Node-RED 0.20.x
RUN apt-get update && apt-get install build-essential python-dev python-pip python-setuptools \
 && curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -  \
 && apt-get install -y nodejs  \
 && npm install -g --unsafe-perm node-red@1.0.3 \
 && npm config set package-lock false \
#configure user login & https security
 && sed -i -e 's+//var fs = require("fs");+var fs = require("fs");+' /usr/lib/node_modules/node-red/settings.js \
 && sed -i -e "s+//    key: fs.readFileSync('privatekey.pem'),+https: {\n    key: fs.readFileSync('/root/.node-red/certs/node-key.pem'),+" /usr/lib/node_modules/node-red/settings.js \
 && sed -i -e "s+//    cert: fs.readFileSync('certificate.pem')+cert: fs.readFileSync('/root/.node-red/certs/node-cert.pem')\n    },+" /usr/lib/node_modules/node-red/settings.js \
 && sed -i -e "s+//requireHttps: true,+requireHttps: true,+" /usr/lib/node_modules/node-red/settings.js \
 && mkdir -p /root/.node-red/node_modules \
 && cd /root/.node-red \
 && npm install when request \
 && mkdir -p /root/.node-red/certs \
 && cd /root/.node-red/certs \
 && openssl genrsa -out ./node-key.pem 2048 \
 && openssl req -new -sha256 -key ./node-key.pem -out ./node-csr.pem -subj "/C=DE/ST=Hessen/L=Hattersheim/O=Hilscher/OU=Hilscher/CN=myown/emailAddress=myown@hilscher.com" \
 && openssl x509 -req -in ./node-csr.pem -signkey ./node-key.pem -out ./node-cert.pem
# -------------------- Install GPIO python lib --------------------------------------
RUN pip install wheel \
 && pip install RPi.GPIO \
 && mkdir /usr/lib/node_modules_tmp
# -------------------- Install netPI user LED nodes and all dependencies --------------------
# && mkdir /usr/lib/node_modules_tmp/node-red-contrib-user-leds \
# && mv ${USER_LEDS_NODE_DIR}/node-red-contrib-user-leds/netiot-io-led.js \
#    ${USER_LEDS_NODE_DIR}/node-red-contrib-user-leds/netiot-io-led.html \
#    ${USER_LEDS_NODE_DIR}/node-red-contrib-user-leds/package.json \
#    -t /usr/lib/node_modules_tmp/node-red-contrib-user-leds \
# && cd /usr/lib/node_modules_tmp/node-red-contrib-user-leds \
# && npm install \
# && mkdir /var/platform \
# && cd /var/platform \
# && ln -s /sys/class/leds/user0:orange:user/brightness led_led2 \
# && ln -s /sys/class/leds/user1:orange:user/brightness led_led1 \
# -------------------- Install NPIX LED nodes and all dependencies --------------------
# && mkdir /usr/lib/node_modules_tmp/node-red-contrib-npix-leds \
# && mv ${NPIX_LEDS_NODE_DIR}/node-red-contrib-npix-leds/npixleds.js \
#    ${NPIX_LEDS_NODE_DIR}/node-red-contrib-npix-leds/npixleds.html \
#    ${NPIX_LEDS_NODE_DIR}/node-red-contrib-npix-leds/package.json \
#    -t /usr/lib/node_modules_tmp/node-red-contrib-npix-leds \
# && cd /usr/lib/node_modules_tmp/node-red-contrib-npix-leds \
# && npm install \
# -------------------- Install Modbus nodes and all dependencies --------------------
RUN npm install -g --unsafe-perm node-red-contrib-modbus@5.2.0
# -------------------- Install Dashboard nodes and all dependencies -----------------
RUN npm install -g --unsafe-perm node-red-dashboard@2.19.3
# -------------------- Install OPC UA nodes and all dependencies --------------------
RUN npm install -g --unsafe-perm node-red-contrib-iiot-opcua@3.12.0
# -------------------- Install MSSQL database node and all dependencies --------------------
RUN npm install -g --unsafe-perm node-red-contrib-mssql-plus@0.3.2
# -------------------- Install PostgresSQL database node and all dependencies --------------------
RUN npm install -g --unsafe-perm node-red-contrib-postgres-variable@0.1.4
# -------------------- Install SMB file access node and all dependencies --------------------
RUN npm install -g --unsafe-perm node-red-contrib-smb@1.1.1
# -------------------- Install S7 communication nodes and all dependencies --------------------
RUN cd /usr/lib/ \
 && npm install -g node-red-contrib-s7comm@1.1.6 \
 && cd /usr/lib/node_modules/node-red-contrib-s7comm/node_modules \
 && npm install -g --unsafe-perm net-keepalive@1.2.1
# -------------------- Install serial port node and all dependencies --------------------
RUN cd /usr/lib/ \
 && npm install -g --unsafe-perm node-red-node-serialport@0.10.0
# && mv /usr/lib/node_modules/node-red-node-serialport /usr/lib/node_modules_tmp\
# -------------------- Do all necessary copies --------------------

#--------------------- Install State machine Node -------------------
RUN npm install -g node-red-contrib-finite-statemachine

#--------------------- Install RPi GPIO Node ------------------------
RUN npm install -g node-red-node-pi-gpio

COPY "./auth/*" /root/.node-red/

#copy files
COPY "./init.d/*" /etc/init.d/

#set the entrypoint
ENTRYPOINT ["/etc/init.d/entrypoint.sh"]

#set STOPSGINAL
STOPSIGNAL SIGTERM

#stop processing ARM emulation (comment out next line if not built as automated build on docker hub)
RUN [ "cross-build-end" ]
