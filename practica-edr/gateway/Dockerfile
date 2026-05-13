FROM debian:bookworm-slim

LABEL maintainer="PracticaEDR"
LABEL description="Gateway/Firewall amb nftables - Zones WAN/LAN/DMZ"

RUN apt-get update && apt-get install -y --no-install-recommends \
    nftables \
    iproute2 \
    iputils-ping \
    tcpdump \
    procps \
    && rm -rf /var/lib/apt/lists/*

COPY sysctl.conf /etc/sysctl.d/99-gateway.conf
COPY nftables.conf /etc/nftables.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
