# Zabbix 7.2 in Docker + Windows-CA (UI) + Mini-CA (agents)

**UI FQDN:** `monitoring.optima.inside`  
**Windows CA:** `ek-ca-01.optima.inside` (domain: `optima.inside`)

## Contents
- `zabbix-server` + `zabbix-web` (alpine-7.2-latest)
- `nginx` TLS termination with Windows-CA server cert
- mTLS to agents using our own mini-CA (clientAuth)
- External PostgreSQL database connection
- Scripts: CSR for server, mini-CA init/issue/revoke, export/restore DB

## Quick start
1. Copy `.env.example` → `.env` and set DB credentials.
2. Generate CSR for **server** and request Windows-CA cert:
   ```bash
   ./scripts/gen_server_csr.sh
   # submit tls/server.csr.pem to ek-ca-01.optima.inside (template: Web Server)
   # put resulting cert/chain here:
   #   secrets/server/server.crt.pem
   #   secrets/server/server.key.pem  (move from tls/server.key.pem)
   #   secrets/server/server.fullchain.pem  (cert + intermediate)
   ```
   *From PFX alternative:*
   ```bash
   openssl pkcs12 -in server.pfx -nocerts -nodes -out tls/server.key.pem
   openssl pkcs12 -in server.pfx -clcerts -nokeys -out tls/server.crt.pem
   openssl pkcs12 -in server.pfx -cacerts -nokeys -out tls/chain.pem
   cat tls/server.crt.pem tls/chain.pem > secrets/server/server.fullchain.pem
   cp tls/server.crt.pem secrets/server/server.crt.pem
   cp tls/server.key.pem secrets/server/server.key.pem
   chmod 600 secrets/server/server.key.pem
   ```
3. Init **mini-CA** for agents and issue at least one client cert:
   ```bash
   ./pki/init_ca.sh
   ./pki/issue_agent_cert.sh host1.optima.inside
   cp pki/certs/agents-ca.crt.pem secrets/agents-ca/agents-ca.crt.pem
   # (optional CRL) ./pki/revoke_agent_cert.sh <CN> -> copy pki/crl/agents-ca.crl.pem to secrets/agents-ca/
   ```
4. Bring up stack:
   ```bash
   docker compose up -d
   ```
5. Open UI: `https://monitoring.optima.inside`

## Zabbix host encryption setup
For each host in Zabbix → **Encryption**:
- Connections to host: **Certificate**
- Issuer: exact Issuer string from agent cert (our mini-CA), e.g.:
  ```bash
  openssl x509 -in pki/certs/host1.optima.inside.crt.pem -noout -issuer -nameopt RFC2253
  ```
- Subject: exact Subject string from the agent cert:
  ```bash
  openssl x509 -in pki/certs/host1.optima.inside.crt.pem -noout -subject -nameopt RFC2253
  ```

## Agent config example (Linux)
```
Server=<IP_or_FQDN_of_Zabbix_server>
ServerActive=<IP_or_FQDN_of_Zabbix_server>
TLSConnect=cert
TLSAccept=cert
TLSCAFile=/etc/zabbix/tls/agents-ca.crt.pem
TLSCertFile=/etc/zabbix/tls/host1.optima.inside.crt.pem
TLSKeyFile=/etc/zabbix/tls/host1.optima.inside.key.pem
```

## DB migration (old systemd install → here)
Export on old host:
```
./scripts/export_old_zabbix_pg.sh --dir backups
```
Restore depends on your DB placement. If you run a Postgres container, see `scripts/restore_zabbix_pg.sh`.

## If ZBX_TLS* envs are ignored
Use config-file override:
- edit `conf/zabbix_server.extra.conf.example` and mount it as `/etc/zabbix/zabbix_server.conf` in `docker-compose.yml`, plus DB settings.
- keep volumes for certs/keys as in compose.

## Security
- Never commit `secrets/`, `.env`, private keys.
- Set `chmod 600` on private keys.
- Keep CRL up to date if you revoke agent certs.
