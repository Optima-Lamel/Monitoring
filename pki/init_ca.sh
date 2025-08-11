#!/usr/bin/env bash
set -euo pipefail
mkdir -p pki/{private,certs,csr,newcerts,crl}
: > pki/index.txt
echo 1000 > pki/serial

openssl genrsa -out pki/private/agents-ca.key.pem 4096
chmod 600 pki/private/agents-ca.key.pem

openssl req -x509 -new -sha256 -days 3650   -key pki/private/agents-ca.key.pem   -out pki/certs/agents-ca.crt.pem   -config pki/openssl-ca.cnf

echo "[✓] CA ready: pki/certs/agents-ca.crt.pem"
