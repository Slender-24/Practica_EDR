# Memòria de la Pràctica EDR — Seguretat i Gestió d'Endpoints
**Autor:** Eduard Tasies
**Data:** 15 de maig de 2026

---

## 1. Introducció i Arquitectura General

En aquesta pràctica he desplegat un entorn de xarxa segmentat utilitzant Docker Compose per simular una arquitectura empresarial amb tres zones diferenciades: **WAN**, **LAN** i **DMZ**. L'objectiu és implementar polítiques de seguretat a nivell de xarxa (Firewall amb nftables) i a nivell de host (EDR amb Wazuh).

### Esquema de l'entorn
L'entorn consta dels següents contenidors:
*   **fw-gateway:** Router/Firewall que interconnecta les xarxes.
*   **dmz-server:** Servidor web Apache i SSH monitoritzat.
*   **lan-client:** Equip de gestió per fer proves.
*   **Stack Wazuh:** Indexer, Manager i Dashboard per a la monitorització EDR.

![Estructura de contenidors](./capturas/Estructura_contenedores.png)
*Captura 1: Verificació de l'estat dels contenidors (Up).*

---

## 2. Exercici 1 — Interconnexió i Seguretat de Xarxa

### 1.a Segmentació de zones
S'han creat subxarxes independents per evitar el moviment lateral no autoritzat. La segmentació s'ha validat comprovant que el tràfic només flueix quan el gateway ho permet explícitament.

<img width="1560" height="657" alt="image" src="https://github.com/user-attachments/assets/3be5285a-6f20-4fb9-8014-ba2ba38350f5" />

*Captura 2: Política de DROP per defecte en la cadena FORWARD.*

**Prova de connectivitat (LAN -> DMZ):**
```bash
# Prova realitzada des de lan-client cap a dmz-server (172.16.0.10)
$ ping -c 3 172.16.0.10
PING 172.16.0.10 (172.16.0.10): 56 data bytes
64 bytes from 172.16.0.10: icmp_seq=0 ttl=63 time=0.124 ms
64 bytes from 172.16.0.10: icmp_seq=1 ttl=63 time=0.156 ms

--- 172.16.0.10 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
```

**Prova de connectivitat bloquejada (DMZ -> LAN):**
```bash
# Intent de ping cap a la LAN (192.168.10.20)
$ docker exec dmz-server ping -c 3 192.168.10.20
PING 192.168.10.20 (192.168.10.20): 56 data bytes
--- 192.168.10.20 ping statistics ---
3 packets transmitted, 0 packets received, 100% packet loss
```

### 1.b Hardening del Gateway (Anti-MITM)
S'han aplicat paràmetres de kernel (`sysctl`) per evitar atacs de redireccionament i rutes falsificades.

![Configuració sysctl](./capturas/Valors_0.png)
*Captura 3: Paràmetres accept_redirects i send_redirects a 0.*

---

## 3. Exercici 2 — Firewalling i Polítiques de Servei

S'han implementat regles **Stateful** que només permeten connexions noves (SYN) per serveis autoritzats, i mantenen la traça de les connexions ja establertes.

### 2.1 HTTP/S i DNS restringit
El servidor DMZ només pot fer consultes DNS al servidor de Cloudflare (1.1.1.1). Qualsevol altre intent és bloquejat.

![Regles HTTP i DNS](./capturas/Captura6.png)
*Captura 4: Regles per als ports 80, 443 i 53 (Whitelist DNS).*

### 2.2 SSH amb Rate Limiting
S'ha configurat un límit de 3 connexions per minut per evitar atacs de força bruta abans que arribin a l'aplicació.

![SSH Rate Limiting](./capturas/Captura8.png)
*Captura 5: Configuració de limit rate a nftables.*

---

## 4. Exercici 3 — Endpoint Detection & Management (Wazuh)

### 3.a Desplegament i Inventari
L'agent de Wazuh ha estat instal·lat al `dmz-server` per recollir telemetria i logs.

**Estat de l'agent al servidor:**
```bash
$ /var/ossec/bin/wazuh-control status
wazuh-modulesd is running...
wazuh-logcollector is running...
wazuh-syscheckd is running...
wazuh-agentd is running...
wazuh-execd is running...
```

### 3.c Resposta Activa (Brute Force)
S'ha simulat un atac de força bruta amb **Hydra** des del `lan-client`. Wazuh ha detectat els múltiples errors de login i ha disparat una acció de **Active Response** per bloquejar la IP al firewall del gateway.

**Execució de l'atac amb Hydra:**
```bash
$ hydra -l testuser -P /opt/wordlists/passwords.txt ssh://172.16.0.10 -t 4
[DATA] attacking ssh://172.16.0.10:22/
[22][ssh] host: 172.16.0.10   login: testuser   password: password123
```

**Bloqueig automàtic al Firewall:**
Després de l'atac, comprovem que la IP de l'atacant ha estat afegida al set de blacklist de nftables per Wazuh:

```bash
$ docker exec gateway nft list set inet filter ssh_blacklist
table inet filter {
    set ssh_blacklist {
        type ipv4_addr
        size 65535
        flags timeout
        elements = { 192.168.10.20 timeout 23h59m55s }
    }
}
```

---

## 5. Anàlisi Tècnic: Sandboxing i Telemetria

### 5.1 Sandboxing: Anàlisi conductual
El sandboxing consisteix a executar fitxers sospitosos en un entorn aïllat per observar el seu comportament sense posar en risc el sistema de producció. Quan l'EDR detecta un fitxer desconegut, l'envia a la sandbox per monitoritzar:
*   **Syscalls:** Apertura de fitxers, creació de nous processos o modificacions al registre.
*   **Xarxa:** Intents de connexió a dominis C2 (Command & Control).
*   **Persistència:** Si intenta instal·lar-se com a servei o modificar claus d'autoarrencada.

Aquesta tècnica és vital per detectar malware de dia zero (0-day) que no té una signatura coneguda encara.

### 5.2 Telemetria i reducció de falsos positius
La telemetria és el flux continu de dades que l'agent envia al manager. En aquest projecte, Wazuh recull telemetria de processos, connexions de xarxa i canvis en fitxers crítics. 
Aquesta dada és fonamental per reduir els falsos positius, ja que permet al motor de correlació entendre el context: una execució de PowerShell pot ser normal en un administrador, però altament sospitosa en un compte de servei d'Apache.

---

## 6. Conclusions i Troubleshooting

Durant el desplegament s'han trobat diversos reptes tècnics que s'han solucionat:
1.  **Imatge Kali mínima:** La imatge `kali-rolling` no incloïa eines bàsiques com `curl` o `ping`. S'ha hagut de modificar el Dockerfile per instal·lar `iputils-ping`, `gnupg` i `ca-certificates`.
2.  **Bucle de reinici:** El contenidor `dmz-server` fallava en l'arrencada perquè l'entrypoint intentava instal·lar paquets sense tenir les dependències de xarxa a punt. S'ha corregit el script `entrypoint.sh` eliminant el `set -e` i assegurant la creació dels fitxers de log abans del `tail`.
3.  **Conflictivitat Firewall/EDR:** Es va detectar que el Rate Limiting del xarxa impedia a vegades que Wazuh detectés la força bruta (ja que el paquet no arribava al host). Es va haver de relaxar la regla de xarxa per permetre que l'EDR pogués realitzar la detecció a capa d'aplicació.
4.  **Wazuh Dashboard:** S'ha utilitzat OpenSearch com a motor d'indexació en lloc d'Elasticsearch per problemes de compatibilitat amb la versió de Wazuh utilitzada. També han hagut problemes amb l'accés al dashboard, que s'han solucionat modificant els ports d'exposició del servei.

L'entorn és ara completament operatiu i compleix amb tots els requisits de segmentació i resposta davant incidents.
