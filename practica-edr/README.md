# Pràctica EDR — Guia de Desplegament
## Requisits a la VM Kali Linux (VirtualBox)

```
RAM mínima: 6 GB (recomanat 8 GB ✅)
Docker Engine >= 24.x
Docker Compose >= 2.x
```

---

## Instal·lació ràpida de Docker a Kali

```bash
# Instal·lar Docker
curl -fsSL https://get.docker.com | bash
systemctl enable docker --now
usermod -aG docker $USER
newgrp docker
```

---

## Passos de desplegament (ordre important)

### 1. Pujar la carpeta a la VM (des del teu PC via MobaXterm)

```bash
# Arrossega la carpeta practica-edr/ a MobaXterm o usa SCP:
scp -r practica-edr/ kali@<IP_VM>:/home/kali/
```

### 2. A la VM Kali — Generar certificats TLS (només 1a vegada)

```bash
cd /home/kali/practica-edr
chmod +x generate-certs.sh
bash generate-certs.sh
```

### 3. Donar permisos als scripts

```bash
chmod +x gateway/entrypoint.sh
chmod +x dmz-server/entrypoint.sh
chmod +x lan-client/entrypoint.sh
chmod +x wazuh/config/active-response/firewall-drop.sh
```

### 4. Configurar el vm.max_map_count (requerit per OpenSearch/Wazuh Indexer)

```bash
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -p
```

### 5. Arrencar tots els serveis

```bash
docker compose up -d --build
```

### 6. Verificar que tots els contenidors estan running

```bash
docker compose ps
```

---

## Verificació de l'entorn

### Exercici 1 — Xarxa segmentada
```bash
# Ping LAN → DMZ (ha de funcionar)
docker exec lan-client ping -c3 172.16.0.10

# Ping DMZ → LAN (ha de ser BLOQUEJAT)
docker exec dmz-server ping -c3 192.168.10.20
# Resultat esperat: 100% packet loss

# Veure regles nftables actives
docker exec gateway nft list ruleset
```

### Exercici 2 — Firewall
```bash
# HTTP des de WAN al DMZ
curl http://172.16.0.10

# SSH des de LAN (ha de funcionar)
docker exec -it lan-client ssh testuser@172.16.0.10

# Veure stats de les regles
docker exec gateway nft list ruleset | grep -A5 "ssh_ratelimit"
```

### Exercici 3 — EDR Wazuh
```bash
# Accés al Dashboard Wazuh
# URL: https://<IP_VM>:443
# Usuari: admin
# Password: SecureIndexer1234!

# Simulació brute force SSH (Exercici 3c)
docker exec -it lan-client bash
hydra -l testuser -P /opt/wordlists/passwords.txt ssh://172.16.0.10 -t 4 -V

# Veure alertes en temps real al manager
docker exec wazuh-manager tail -f /var/ossec/logs/alerts/alerts.json | python3 -m json.tool

# Veure IPs bloquejades per Active Response
docker exec dmz-server iptables -L INPUT -n | grep DROP

# Simulació binari sospitós (Exercici 3b)
docker exec dmz-server socat TCP:8.8.8.8:80 -
# → Ha de generar alerta Wazuh amb audit key SUSPICIOUS_BINARY
```

---

## Adreces IP de l'entorn

| Contenidor | Xarxa | IP |
|---|---|---|
| gateway (WAN) | net_wan | 10.0.0.1 |
| gateway (LAN) | net_lan | 192.168.10.1 |
| gateway (DMZ) | net_dmz | 172.16.0.1 |
| dmz-server | net_dmz | 172.16.0.10 |
| lan-client | net_lan | 192.168.10.20 |
| wazuh-manager | net_lan | 192.168.10.30 |
| wazuh-indexer | net_lan | 192.168.10.31 |
| wazuh-dashboard | net_lan | 192.168.10.32 |

---

## Ports exposats a la VM

| Port VM | Servei | Contenidor |
|---|---|---|
| 8080 | HTTP Apache DMZ | dmz-server |
| 2222 | SSH DMZ | dmz-server |
| 443 | Wazuh Dashboard | wazuh-dashboard |
| 55000 | Wazuh API | wazuh-manager |

---

## Logs útils

```bash
# Logs del gateway (nftables)
docker logs gateway -f

# Logs del servidor DMZ
docker logs dmz-server -f

# Alertes Wazuh (JSON)
docker exec wazuh-manager cat /var/ossec/logs/alerts/alerts.json

# Active responses executades
docker exec wazuh-manager cat /var/ossec/logs/active-responses.log
```

---

## Aturar l'entorn

```bash
docker compose down
# Per eliminar també els volums (reset complet):
docker compose down -v
```
