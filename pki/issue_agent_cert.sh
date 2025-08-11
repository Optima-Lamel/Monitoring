#!/usr/bin/env bash
set -euo pipefail
# Usage: ./pki/issue_agent_cert.sh host.fqdn [SAN2] [SAN3] ...
CN="${1:-}"; shift || true
[[ -z "$CN" ]] && { echo "Usage: $0 <CN> [SAN ...]"; exit 1; }

SAN="DNS:${CN}"
for a in "$@"; do
  [[ "$a" == DNS:* || "$a" == IP:* ]] && SAN="${SAN},${a}" || SAN="${SAN},DNS:${a}"
done

openssl genrsa -out "pki/private/${CN}.key.pem" 2048
chmod 600 "pki/private/${CN}.key.pem"

openssl req -new -sha256   -key "pki/private/${CN}.key.pem"   -out "pki/csr/${CN}.csr.pem"   -subj "/C=RU/ST=Moscow/L=Moscow/O=Optima/OU=IT/CN=${CN}"   -addext "subjectAltName=${SAN}"

openssl ca -batch -config pki/openssl-ca.cnf   -extensions v3_client   -in "pki/csr/${CN}.csr.pem"   -out "pki/certs/${CN}.crt.pem"   -days 825 -notext -md sha256

cat "pki/certs/${CN}.crt.pem" "pki/certs/agents-ca.crt.pem" > "pki/certs/${CN}.fullchain.pem"

echo "[✓] Issued:"
echo "  Key : pki/private/${CN}.key.pem"
echo "  Cert: pki/certs/${CN}.crt.pem"
echo "  CA  : pki/certs/agents-ca.crt.pem"
