FROM kalilinux/kali-rolling

LABEL maintainer="PracticaEDR"
LABEL description="LAN Client: gestio + eines de test (Hydra, nmap, SSH)"

ENV DEBIAN_FRONTEND=noninteractive

# Kali minimal NO porta ping per defecte
RUN apt-get update && apt-get install -y --no-install-recommends \
    hydra \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Llista de contrasenyes per brute force (Exercici 3c)
COPY wordlists/passwords.txt /opt/wordlists/passwords.txt

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
