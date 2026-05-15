FROM kalilinux/kali-rolling

LABEL maintainer="PracticaEDR"
LABEL description="Servidor DMZ: Apache2 + SSH + auditd + Wazuh Agent"

ENV DEBIAN_FRONTEND=noninteractive

# Kali ja té: curl, wget, gnupg, python3, iproute2, iptables,
# procps, net-tools, sudo, iputils-ping → NO cal reinstal·lar-los
# Només instal·lem el que FALTA a Kali base:
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    openssh-server \
    auditd \
    audispd-plugins \
    curl \
    gnupg \
    ca-certificates \
    iputils-ping \
    iproute2 \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Usuari SSH de prova (target del brute force - Exercici 3c)
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser:password123" | chpasswd && \
    mkdir -p /run/sshd

COPY ssh/sshd_config /etc/ssh/sshd_config
COPY apache/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY audit/audit.rules /etc/audit/rules.d/edr.rules
COPY wazuh-agent/ossec.conf /tmp/ossec.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 80

ENTRYPOINT ["/entrypoint.sh"]
