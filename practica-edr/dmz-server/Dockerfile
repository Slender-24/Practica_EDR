FROM ubuntu:22.04

LABEL maintainer="PracticaEDR"
LABEL description="Servidor DMZ: Apache2 + SSH + auditd + Wazuh Agent"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Madrid

RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    openssh-server \
    auditd \
    audispd-plugins \
    curl \
    wget \
    gnupg \
    lsb-release \
    chrony \
    iproute2 \
    iputils-ping \
    iptables \
    procps \
    net-tools \
    sudo \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# ── Wazuh Agent ───────────────────────────────────────────
RUN curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor \
        -o /usr/share/keyrings/wazuh.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] \
        https://packages.wazuh.com/4.x/apt/ stable main" \
        > /etc/apt/sources.list.d/wazuh.list && \
    apt-get update && \
    apt-get install -y wazuh-agent && \
    rm -rf /var/lib/apt/lists/*

# ── Usuari SSH de prova (brute force target) ──────────────
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser:password123" | chpasswd && \
    mkdir -p /run/sshd

# ── Configuració SSH ──────────────────────────────────────
COPY ssh/sshd_config /etc/ssh/sshd_config

# ── Configuració Apache ───────────────────────────────────
COPY apache/000-default.conf /etc/apache2/sites-available/000-default.conf

# ── Regles auditd ─────────────────────────────────────────
COPY audit/audit.rules /etc/audit/rules.d/edr.rules

# ── Configuració Wazuh Agent ──────────────────────────────
COPY wazuh-agent/ossec.conf /var/ossec/etc/ossec.conf

# ── Entrypoint ────────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 80 443

ENTRYPOINT ["/entrypoint.sh"]
