#!/bin/bash
# ============================================================
#  ACTIVE RESPONSE — firewall-drop.sh
#  Exercici 3c: Bloqueig automàtic d'IP atacant 24 hores
#
#  Wazuh crida aquest script quan detecta brute force SSH.
#  Afegeix la IP a la llista negra d'iptables durant 86400s.
#
#  Arguments de Wazuh: $1=acció (add/delete) $2=usuari $3=ip
#                      $4=alerta_id $5=regla_id $6=agent_name
# ============================================================

# Log de l'Active Response
LOG_FILE="/var/ossec/logs/active-responses.log"
ACTION=$1
USER=$2
IP=$3
ALERT_ID=$4
RULE_ID=$5

echo "$(date '+%Y/%m/%d %H:%M:%S') - firewall-drop.sh: Acció=$ACTION IP=$IP Regla=$RULE_ID" >> $LOG_FILE

# Validar que l'IP no és buida ni és una IP local
if [ -z "$IP" ] || [ "$IP" = "-" ]; then
    echo "$(date '+%Y/%m/%d %H:%M:%S') - firewall-drop.sh: ERROR - IP buida o invàlida" >> $LOG_FILE
    exit 1
fi

# No bloquejar IPs de les xarxes internes
if echo "$IP" | grep -qE '^(192\.168\.|172\.16\.|10\.|127\.)'; then
    echo "$(date '+%Y/%m/%d %H:%M:%S') - firewall-drop.sh: SKIP - IP interna $IP no es bloqueja" >> $LOG_FILE
    exit 0
fi

case "$ACTION" in
    "add")
        echo "$(date '+%Y/%m/%d %H:%M:%S') - firewall-drop.sh: BLOQUEJANT IP $IP durant 86400s (24h)" >> $LOG_FILE

        # Bloquejar amb iptables
        /sbin/iptables -I INPUT -s "$IP" -j DROP
        /sbin/iptables -I FORWARD -s "$IP" -j DROP

        # Programar desbloqueig automàtic als 86400 segons (24h)
        (sleep 86400 && \
         /sbin/iptables -D INPUT -s "$IP" -j DROP 2>/dev/null; \
         /sbin/iptables -D FORWARD -s "$IP" -j DROP 2>/dev/null; \
         echo "$(date '+%Y/%m/%d %H:%M:%S') - firewall-drop.sh: IP $IP DESBLOQUEJADA (timeout 24h)" >> $LOG_FILE) &

        echo "$(date '+%Y/%m/%d %H:%M:%S') - firewall-drop.sh: IP $IP afegida a la llista negra correctament" >> $LOG_FILE
        ;;

    "delete")
        echo "$(date '+%Y/%m/%d %H:%M:%S') - firewall-drop.sh: DESBLOQUEJANT IP $IP" >> $LOG_FILE
        /sbin/iptables -D INPUT -s "$IP" -j DROP 2>/dev/null
        /sbin/iptables -D FORWARD -s "$IP" -j DROP 2>/dev/null
        echo "$(date '+%Y/%m/%d %H:%M:%S') - firewall-drop.sh: IP $IP eliminada de la llista negra" >> $LOG_FILE
        ;;

    *)
        echo "$(date '+%Y/%m/%d %H:%M:%S') - firewall-drop.sh: Acció desconeguda: $ACTION" >> $LOG_FILE
        exit 1
        ;;
esac

exit 0
