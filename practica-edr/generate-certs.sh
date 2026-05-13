#!/bin/bash
# ============================================================
#  SCRIPT — Generació de certificats TLS per a Wazuh
#  Executa'l UNA SOLA VEGADA a la VM Kali abans del primer
#  docker compose up
#
#  Ús: bash wazuh/generate-certs.sh
# ============================================================
set -e

CERTS_DIR="./wazuh/certs"
mkdir -p "$CERTS_DIR"

echo "[*] Generant CA arrel (root-ca)..."
openssl genrsa -out "$CERTS_DIR/root-ca-key.pem" 2048
openssl req -new -x509 -sha256 \
    -key "$CERTS_DIR/root-ca-key.pem" \
    -out "$CERTS_DIR/root-ca.pem" \
    -days 3650 \
    -subj "/C=ES/ST=Catalunya/L=Barcelona/O=PracticaEDR/CN=WazuhRootCA"

echo "[*] Generant certificat per a wazuh-indexer..."
openssl genrsa -out "$CERTS_DIR/wazuh-indexer-key.pem" 2048
openssl req -new \
    -key "$CERTS_DIR/wazuh-indexer-key.pem" \
    -out "$CERTS_DIR/wazuh-indexer.csr" \
    -subj "/C=ES/ST=Catalunya/O=PracticaEDR/CN=wazuh-indexer"
openssl x509 -req -sha256 -days 3650 \
    -in "$CERTS_DIR/wazuh-indexer.csr" \
    -CA "$CERTS_DIR/root-ca.pem" \
    -CAkey "$CERTS_DIR/root-ca-key.pem" \
    -CAcreateserial \
    -out "$CERTS_DIR/wazuh-indexer.pem"

echo "[*] Generant certificat per a wazuh-manager (filebeat)..."
openssl genrsa -out "$CERTS_DIR/wazuh-manager-key.pem" 2048
openssl req -new \
    -key "$CERTS_DIR/wazuh-manager-key.pem" \
    -out "$CERTS_DIR/wazuh-manager.csr" \
    -subj "/C=ES/ST=Catalunya/O=PracticaEDR/CN=wazuh-manager"
openssl x509 -req -sha256 -days 3650 \
    -in "$CERTS_DIR/wazuh-manager.csr" \
    -CA "$CERTS_DIR/root-ca.pem" \
    -CAkey "$CERTS_DIR/root-ca-key.pem" \
    -CAcreateserial \
    -out "$CERTS_DIR/wazuh-manager.pem"

echo "[*] Generant certificat per a wazuh-dashboard..."
openssl genrsa -out "$CERTS_DIR/wazuh-dashboard-key.pem" 2048
openssl req -new \
    -key "$CERTS_DIR/wazuh-dashboard-key.pem" \
    -out "$CERTS_DIR/wazuh-dashboard.csr" \
    -subj "/C=ES/ST=Catalunya/O=PracticaEDR/CN=wazuh-dashboard"
openssl x509 -req -sha256 -days 3650 \
    -in "$CERTS_DIR/wazuh-dashboard.csr" \
    -CA "$CERTS_DIR/root-ca.pem" \
    -CAkey "$CERTS_DIR/root-ca-key.pem" \
    -CAcreateserial \
    -out "$CERTS_DIR/wazuh-dashboard.pem"

# Còpia de CA per al manager (nom diferent requerit per Wazuh)
cp "$CERTS_DIR/root-ca.pem" "$CERTS_DIR/root-ca-manager.pem"

# Permisos correctes
chmod 400 "$CERTS_DIR"/*-key.pem
chmod 444 "$CERTS_DIR"/*.pem

# Netejar CSRs temporals
rm -f "$CERTS_DIR"/*.csr "$CERTS_DIR"/*.srl

echo ""
echo "[+] Certificats generats correctament a: $CERTS_DIR"
echo "[+] Ara pots executar: docker compose up -d"
ls -la "$CERTS_DIR"
