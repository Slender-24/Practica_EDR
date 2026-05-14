FROM alpine:3.19

LABEL maintainer="PracticaEDR"
LABEL description="Gateway/Firewall amb nftables - Zones WAN/LAN/DMZ"

RUN apk add --no-cache \
    nftables \
    iproute2 \
    iputils \
    tcpdump \
    procps \
    bash

COPY sysctl.conf /etc/sysctl.d/99-gateway.conf
COPY nftables.conf /etc/nftables.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
