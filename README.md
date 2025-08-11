# 🇷🇺 Zabbix 7.2 в Docker + Windows-CA (UI) + Mini-CA (агенты) 🐳🔒

**UI FQDN:** `monitoring.optima.inside`  
**Windows CA:** `ek-ca-01.optima.inside` (домен: `optima.inside`)

## 📦 Состав
- `zabbix-server` + `zabbix-web` (alpine-7.2-latest)
- `nginx` с TLS-терминацией и серверным сертификатом от Windows-CA
- mTLS для агентов с использованием собственного mini-CA (clientAuth)
- Внешнее подключение к базе данных PostgreSQL
- Скрипты: создание CSR для сервера, инициализация/выдача/отзыв mini-CA, экспорт/восстановление БД

## 🚀 Быстрый старт
1. Скопируйте `.env.example` → `.env` и укажите параметры БД.
2. Сгенерируйте CSR для **сервера** и запросите сертификат у Windows-CA:
   ```bash
   ./scripts/gen_server_csr.sh
   # отправьте tls/server.csr.pem на ek-ca-01.optima.inside (шаблон: Web Server)
   # поместите полученные сертификаты/цепочку сюда:
   #   secrets/server/server.crt.pem
   #   secrets/server/server.key.pem  (переместить из tls/server.key.pem)
   #   secrets/server/server.fullchain.pem  (сертификат + промежуточный)
   ```
   *Альтернатива из PFX:*
   ```bash
   openssl pkcs12 -in server.pfx -nocerts -nodes -out tls/server.key.pem
   openssl pkcs12 -in server.pfx -clcerts -nokeys -out tls/server.crt.pem
   openssl pkcs12 -in server.pfx -cacerts -nokeys -out tls/chain.pem
   cat tls/server.crt.pem tls/chain.pem > secrets/server/server.fullchain.pem
   cp tls/server.crt.pem secrets/server/server.crt.pem
   cp tls/server.key.pem secrets/server/server.key.pem
   chmod 600 secrets/server/server.key.pem
   ```
3. Инициализируйте **mini-CA** для агентов и выпустите хотя бы один клиентский сертификат:
   ```bash
   ./pki/init_ca.sh
   ./pki/issue_agent_cert.sh host1.optima.inside
   cp pki/certs/agents-ca.crt.pem secrets/agents-ca/agents-ca.crt.pem
   # (опционально CRL) ./pki/revoke_agent_cert.sh <CN> -> скопируйте pki/crl/agents-ca.crl.pem в secrets/agents-ca/
   ```
4. Запустите стек:
   ```bash
   docker compose up -d
   ```
5. Откройте UI: `https://monitoring.optima.inside`

## 🖥️ Настройка шифрования хоста Zabbix
Для каждого хоста в Zabbix → **Encryption**:
- Connections to host: **Certificate**
- Issuer: точная строка Issuer из сертификата агента (наш mini-CA), например:
  ```bash
  openssl x509 -in pki/certs/host1.optima.inside.crt.pem -noout -issuer -nameopt RFC2253
  ```
- Subject: точная строка Subject из сертификата агента:
  ```bash
  openssl x509 -in pki/certs/host1.optima.inside.crt.pem -noout -subject -nameopt RFC2253
  ```

## 🐧 Пример конфига агента (Linux)
```
Server=<IP_или_FQDN_сервера_Zabbix>
ServerActive=<IP_или_FQDN_сервера_Zabbix>
TLSConnect=cert
TLSAccept=cert
TLSCAFile=/etc/zabbix/tls/agents-ca.crt.pem
TLSCertFile=/etc/zabbix/tls/host1.optima.inside.crt.pem
TLSKeyFile=/etc/zabbix/tls/host1.optima.inside.key.pem
```

## 🗄️ Миграция БД (со старой systemd-установки → сюда)
Экспорт на старом хосте:
```
./scripts/export_old_zabbix_pg.sh --dir backups
```
Восстановление зависит от размещения вашей БД. Если вы используете контейнер Postgres, смотрите `scripts/restore_zabbix_pg.sh`.

## ⚠️ Если переменные окружения ZBX_TLS* игнорируются
Используйте override-файл конфига:
- отредактируйте `conf/zabbix_server.extra.conf.example` и смонтируйте его как `/etc/zabbix/zabbix_server.conf` в `docker-compose.yml`, плюс параметры БД.
- оставьте volume для сертификатов/ключей как в compose.

## 🔐 Безопасность
- Никогда не коммитьте `secrets/`, `.env`, приватные ключи.
- Устанавливайте `chmod 600` на приватные ключи.
- Держите CRL актуальным при отзыве сертификатов
