#!/bin/bash
# ============================================================
#  DMZ-SERVER — Entrypoint optimitzat
#  El Wazuh Agent s'instal·la aquí (1a vegada) per no alentir el build
# ============================================================
set -e

# ── 1. Instal·lar Wazuh Agent si no està instal·lat ──────
if ! command -v wazuh-agentd &>/dev/null && [ ! -f /var/ossec/bin/wazuh-agentd ]; then
    echo "[*] Instal·lant Wazuh Agent (primera execució)..."
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor \
        -o /usr/share/keyrings/wazuh.gpg
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] \
        https://packages.wazuh.com/4.x/apt/ stable main" \
        > /etc/apt/sources.list.d/wazuh.list
    apt-get update -qq
    apt-get install -y --no-install-recommends wazuh-agent
    rm -rf /var/lib/apt/lists/*
    echo "[+] Wazuh Agent instal·lat."
else
    echo "[*] Wazuh Agent ja instal·lat, saltant..."
fi

# ── 2. Configurar Wazuh Agent ────────────────────────────
echo "[*] Configurant Wazuh Agent..."
cp /tmp/ossec.conf /var/ossec/etc/ossec.conf
sed -i "s/WAZUH_MANAGER_IP/${WAZUH_MANAGER:-192.168.10.30}/" /var/ossec/etc/ossec.conf
sed -i "s/AGENT_NAME/${WAZUH_AGENT_NAME:-dmz-server}/" /var/ossec/etc/ossec.conf

# ── 3. Generar claus SSH del servidor ───────────────────
echo "[*] Generant claus SSH..."
ssh-keygen -A 2>/dev/null || true

# ── 4. Iniciar auditd ────────────────────────────────────
echo "[*] Iniciant auditd..."
auditd -b 2>/dev/null || true
sleep 1
auditctl -R /etc/audit/rules.d/edr.rules 2>/dev/null || true

# ── 5. Iniciar Apache2 ───────────────────────────────────
echo "[*] Iniciant Apache2..."
service apache2 start

# ── 6. Iniciar SSH ───────────────────────────────────────
echo "[*] Iniciant SSH..."
service ssh start

# ── 7. Iniciar Wazuh Agent ───────────────────────────────
echo "[*] Iniciant Wazuh Agent..."
/var/ossec/bin/wazuh-control start 2>/dev/null || true

echo ""
echo "=========================================="
echo "  DMZ-SERVER OPERATIU"
echo "  IP: $(hostname -I | awk '{print $1}')"
echo "  Apache: http://$(hostname -I | awk '{print $1}')"
echo "  SSH:    $(hostname -I | awk '{print $1}'):22"
echo "=========================================="

exec tail -f /var/log/apache2/access.log /var/log/auth.log 2>/dev/null || \
     tail -f /dev/null
