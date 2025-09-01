#!/usr/bin/env bash
set -euo pipefail
mkdir -p tls
openssl genrsa -out tls/server.key.pem 2048
chmod 600 tls/server.key.pem
openssl req -new -key tls/server.key.pem   -out tls/server.csr.pem   -config tls/openssl-zabbix-server.cnf
echo "[i] Submit tls/server.csr.pem to Windows CA at ek-ca-01.optima.inside (domain: optima.inside)"
