#!/usr/bin/env bash
set -euo pipefail
CN="${1:-}"; [[ -z "$CN" ]] && { echo "Usage: $0 <CN>"; exit 1; }
openssl ca -config pki/openssl-ca.cnf -revoke "pki/certs/${CN}.crt.pem"
openssl ca -gencrl -config pki/openssl-ca.cnf -out pki/crl/agents-ca.crl.pem
echo "[✓] Revoked ${CN}, CRL: pki/crl/agents-ca.crl.pem"
