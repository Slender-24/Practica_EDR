#!/bin/bash
# DMZ-SERVER — Entrypoint robusto

# 1. Instal·lar Wazuh Agent (si falla la red, el contenedor NO muere)
if [ ! -f /var/ossec/bin/wazuh-agentd ]; then
    echo "[*] Intentant instal·lar Wazuh Agent..."
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg || true
    echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list || true
    apt-get update -qq || true
    apt-get install -y wazuh-agent || true
fi

# 2. Configurar Wazuh
if [ -d /var/ossec/etc ]; then
    cp /tmp/ossec.conf /var/ossec/etc/ossec.conf || true
    sed -i "s/WAZUH_MANAGER_IP/${WAZUH_MANAGER:-192.168.10.30}/" /var/ossec/etc/ossec.conf || true
fi

# 3. Iniciar servicios
ssh-keygen -A 2>/dev/null || true
service apache2 start || true
service ssh start || true
/var/ossec/bin/wazuh-control start 2>/dev/null || true

# 4. Asegurar que los logs existen para que tail no falle
mkdir -p /var/log/apache2
touch /var/log/apache2/access.log /var/log/auth.log

echo "[+] DMZ-SERVER operatiu."

# Mantenir el contenidor actiu pase lo que pase
exec tail -f /var/log/apache2/access.log /var/log/auth.log /dev/null
