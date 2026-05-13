#!/bin/bash
# ============================================================
#  DMZ-SERVER — Entrypoint
#  Inicia: auditd, SSH, Apache2, Wazuh Agent
# ============================================================
set -e

echo "[*] Configurant Wazuh Agent..."
# Substituir IP del manager dinàmicament
sed -i "s/WAZUH_MANAGER_IP/${WAZUH_MANAGER:-192.168.10.30}/" /var/ossec/etc/ossec.conf
sed -i "s/AGENT_NAME/${WAZUH_AGENT_NAME:-dmz-server}/" /var/ossec/etc/ossec.conf

echo "[*] Generant claus SSH del servidor..."
ssh-keygen -A

echo "[*] Iniciant auditd..."
auditd -b || true
sleep 1

echo "[*] Carregant regles d'auditoria EDR..."
auditctl -R /etc/audit/rules.d/edr.rules 2>/dev/null || true

echo "[*] Iniciant Apache2..."
service apache2 start

echo "[*] Iniciant SSH..."
service ssh start

echo "[*] Iniciant Wazuh Agent..."
/var/ossec/bin/wazuh-agentd &
/var/ossec/bin/wazuh-logcollector &
/var/ossec/bin/wazuh-syscheckd &
/var/ossec/bin/wazuh-modulesd &

echo "[+] Tots els serveis inicials actius al servidor DMZ."
echo "[+] IP DMZ: $(hostname -I | awk '{print $1}')"

# Mantenir el contenidor actiu i mostrar logs
exec tail -f /var/log/apache2/access.log /var/log/auth.log 2>/dev/null || \
     tail -f /dev/null
