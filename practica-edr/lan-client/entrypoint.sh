#!/bin/bash
# ============================================================
#  LAN-CLIENT — Entrypoint
#  Client de gestió de la LAN. Eines disponibles:
#    - hydra: atac brute force SSH (Exercici 3c)
#    - nmap:  escaneig de ports
#    - ssh:   connexió de gestió al DMZ
# ============================================================

echo "============================================"
echo "  LAN CLIENT OPERATIU"
echo "  IP LAN: $(hostname -I | awk '{print $1}')"
echo "============================================"
echo ""
echo "  Eines disponibles:"
echo "  - Ping al DMZ:  ping 172.16.0.10"
echo "  - SSH al DMZ:   ssh testuser@172.16.0.10"
echo "  - Brute Force:  hydra -l testuser -P /opt/wordlists/passwords.txt"
echo "                        ssh://172.16.0.10 -t 4 -V"
echo "  - Scan DMZ:     nmap -sS -O 172.16.0.10"
echo "============================================"

# Mantenir el contenidor actiu (per entrar amb docker exec)
exec tail -f /dev/null
