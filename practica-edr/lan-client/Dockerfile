FROM kalilinux/kali-rolling:latest

LABEL maintainer="PracticaEDR"
LABEL description="LAN Client: gestió + eines de test (Hydra, nmap, SSH)"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    hydra \
    nmap \
    openssh-client \
    iputils-ping \
    iproute2 \
    curl \
    wget \
    netcat-traditional \
    net-tools \
    procps \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Llista de contrasenyes per brute force (Exercici 3c)
COPY wordlists/passwords.txt /opt/wordlists/passwords.txt

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
