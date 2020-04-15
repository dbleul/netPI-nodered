
#use armv7hf compatible base image
FROM balenalib/armv7hf-debian:buster-20191223

#dynamic build arguments coming from the /hooks/build file
ARG BUILD_DATE
ARG VCS_REF

#metadata labels
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/HilscherAutomation/netPI-netx-ethernet-lan" \
      org.label-schema.vcs-ref=$VCS_REF

#enable building ARM container on x86 machinery on the web (comment out next line if not built as automated build on docker hub)
RUN [ "cross-build-start" ]


#labeling
LABEL maintainer="DennisB" \
      version=1.0.5.0 \
      description="Node-Red for NetPi with no netX Card"

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
#clean up
    && rm -rf /tmp/* \
    && apt-get remove build-essential \
    && apt-get -yqq autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*

# -------------------- Install nodejs and Node-RED --------------------------------------
RUN apt-get update && apt-get install build-essential python-dev python-pip python-setuptools \
 && curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -  \
 && apt-get install -y nodejs  \
 && npm install --unsafe-perm node-red@1.0.5 \
 && npm config set package-lock false \
#configure user login & https security
 && sed -i -e 's+//var fs = require("fs");+var fs = require("fs");+' /usr/lib/node_modules/node-red/settings.js \
 && sed -i -e "s+//    key: fs.readFileSync('privatekey.pem'),+https: {\n    key: fs.readFileSync('/root/.node-red-certs/node-key.pem'),+" /usr/lib/node_modules/node-red/settings.js \
 && sed -i -e "s+//    cert: fs.readFileSync('certificate.pem')+cert: fs.readFileSync('/root/.node-red-certs/node-cert.pem')\n    },+" /usr/lib/node_modules/node-red/settings.js \
 && sed -i -e "s+//requireHttps: true,+requireHttps: true,+" /usr/lib/node_modules/node-red/settings.js \
 && mkdir -p /root/.node-red/node_modules \
 && cd /usr/lib/ \
 && npm install when request \
 && mkdir -p /root/.node-red-certs \
 && cd /root/.node-red-certs \
 && openssl genrsa -out ./node-key.pem 2048 \
 && openssl req -new -sha256 -key ./node-key.pem -out ./node-csr.pem -subj "/C=DE/ST=Hessen/L=Hattersheim/O=Hilscher/OU=Hilscher/CN=myown/emailAddress=myown@hilscher.com" \
 && openssl x509 -req -in ./node-csr.pem -signkey ./node-key.pem -out ./node-cert.pem
# -------------------- Install GPIO python lib --------------------------------------
RUN pip install wheel \
 && pip install RPi.GPIO \
 && mkdir /usr/lib/node_modules_tmp
# -------------------- Install Modbus nodes and all dependencies --------------------
RUN cd /usr/lib/ \
&& npm install --unsafe-perm node-red-contrib-modbus@5.10.1
# -------------------- Install Dashboard nodes and all dependencies -----------------
RUN cd /usr/lib/ \
&& npm install --unsafe-perm node-red-dashboard@2.20.0
# -------------------- Install OPC UA nodes and all dependencies --------------------
RUN cd /usr/lib/ \
&& npm install --unsafe-perm node-red-contrib-iiot-opcua@3.12.0
# -------------------- Install MSSQL database node and all dependencies --------------------
RUN cd /usr/lib/ \
&& npm install --unsafe-perm node-red-contrib-mssql-plus@0.4.0
# -------------------- Install PostgresSQL database node and all dependencies --------------------
RUN cd /usr/lib/ \
&& npm install --unsafe-perm node-red-contrib-postgres-variable@0.1.4
# -------------------- Install SMB file access node and all dependencies --------------------
RUN cd /usr/lib/ \
&& npm install --unsafe-perm node-red-contrib-smb@1.1.1
# -------------------- Install S7 communication nodes and all dependencies --------------------
RUN cd /usr/lib/ \
 && npm install node-red-contrib-s7comm@1.1.6 \
 && cd /usr/lib/node_modules/node-red-contrib-s7comm/node_modules \
 && npm install --unsafe-perm net-keepalive@1.2.1
# -------------------- Install serial port node and all dependencies --------------------
RUN cd /usr/lib/ \
 && npm install --unsafe-perm node-red-node-serialport@0.10.1

#--------------------- Install State machine Node -------------------
RUN cd /usr/lib/ \
&& npm install node-red-contrib-finite-statemachine@0.2.10

#--------------------- Install RPi GPIO Node ------------------------
RUN cd /usr/lib/ \
&& npm install node-red-node-pi-gpio

#copy files
COPY "./init.d/*" /etc/init.d/

RUN chmod 777 /etc/init.d/entrypoint.sh \
&& chmod +x /etc/init.d/entrypoint.sh

#set the entrypoint
ENTRYPOINT ["/etc/init.d/entrypoint.sh"]

#set STOPSGINAL
STOPSIGNAL SIGTERM

#stop processing ARM emulation (comment out next line if not built as automated build on docker hub)
RUN [ "cross-build-end" ]
