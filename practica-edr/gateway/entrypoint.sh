#!/bin/bash
# ============================================================
#  GATEWAY — Entrypoint
#  Carrega sysctl i nftables, i manté el contenidor actiu
# ============================================================
set -e

echo "[*] Aplicant paràmetres sysctl de seguretat..."
sysctl -p /etc/sysctl.d/99-gateway.conf 2>/dev/null || true

echo "[*] Carregant regles nftables..."
nft -f /etc/nftables.conf

echo "[*] Verificant regles actives:"
nft list ruleset

echo "[+] Gateway operatiu. Premeu Ctrl+C per aturar."
# Mantenir el contenidor actiu
exec tail -f /dev/null
