# 🇷🇺 Zabbix 7.4 в Docker + PSK для агентов 🐳🔒

**UI FQDN:** `yourdomain.com`  

---

## 📦 Состав проекта

- **База данных:** PostgreSQL 17 (контейнер)
- **Zabbix Server:** `zabbix/zabbix-server-pgsql:alpine-7.4-latest`
- **Zabbix Web:** `zabbix/zabbix-web-nginx-pgsql:alpine-7.4-latest`
- **Nginx:** TLS-терминация
- **PSK для агентов:** безопасное подключение через предварительно согласованный ключ (PSK)

---

## 🚀 Быстрый старт

1. **Скопируйте и настройте переменные окружения:**

   ```shell
   cp .env.example .env
   # Укажите параметры БД и сервера в .env
   ```

2. **Создайте PSK для агентов:**

   ```shell
   openssl rand -hex 32 > /opt/zabbix/ssl/zabbix_agentd.psk
   # или используйте свой путь, но не коммитьте этот файл!
   ```

3. **Запуск стека:**

   ```shell
   docker compose up -d
   ```

4. **Откройте веб-интерфейс:**  
   [https://yourdomain.com](https://yourdomain.com)

---

## 🖥️ Настройка шифрования хоста Zabbix (PSK)

Для каждого хоста в Zabbix → **Encryption**:

- Connections to host: **PSK**
- PSK identity: строка-идентификатор (например, `zabbix-psk`)
- PSK: содержимое файла `/opt/zabbix/ssl/zabbix_agentd.psk` (или вашего пути)

---

## 🐧 Пример конфига агента (Linux, PSK)

```ini
Server=<IP_или_FQDN_сервера_Zabbix>
ServerActive=<IP_или_FQDN_сервера_Zabbix>
TLSConnect=psk
TLSAccept=psk
TLSPSKIdentity=zabbix-psk
TLSPSKFile=/etc/zabbix/zabbix_agentd.psk
```

---

## 🔐 Безопасность

- Никогда не коммитьте приватные ключи и PSK-файлы
- Устанавливайте `chmod 600` на PSK-файлы
- Периодически меняйте PSK для повышения безопасности

---

## 📝 Примечания

- Все контейнеры объединены в одну сеть `zbx-net`
- Для хранения данных Postgres используется volume `zbx-pgdata`
- PSK-файлы должны быть защищены и доступны только необходимым пользователям

---

## 🚀 Быстрый старт

1. **Скопируйте и настройте переменные окружения:**
   ```
   cp .env.example .env
   # Укажите параметры БД и сервера в .env
   ```

2. **Генерация CSR для сервера и получение сертификата от Windows-CA:**
   ```bash
   ./scripts/gen_server_csr.sh
   # Отправьте tls/server.csr.pem на Ваш CA (шаблон: Web Server)
   # Поместите полученные файлы:
   #   secrets/server/server.crt.pem
   #   secrets/server/server.key.pem  (из tls/server.key.pem)
   #   secrets/server/server.fullchain.pem  (сертификат + цепочка)
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

3. **Создайте PSK для агентов:**
   ```bash
   openssl rand -hex 32 > /opt/zabbix/ssl/zabbix_agentd.psk
   # или используйте свой путь, но не коммитьте этот файл!
   ```

4. **Запуск стека:**
   ```bash
   docker compose up -d
   ```

5. **Откройте веб-интерфейс:**  
   [https://yourdomain.com](https://yourdomain.com)

---

## 🖥️ Настройка шифрования хоста Zabbix (PSK)

Для каждого хоста в Zabbix → **Encryption**:
- Connections to host: **PSK**
- PSK identity: строка-идентификатор (например, `zabbix-psk`)
- PSK: содержимое файла `/opt/zabbix/ssl/zabbix_agentd.psk` (или вашего пути)

---

## 🐧 Пример конфига агента (Linux, PSK)

```
Server=<IP_или_FQDN_сервера_Zabbix>
ServerActive=<IP_или_FQDN_сервера_Zabbix>
TLSConnect=psk
TLSAccept=psk
TLSPSKIdentity=zabbix-psk
TLSPSKFile=/etc/zabbix/zabbix_agentd.psk
```

---

## 🗄️ Миграция БД (со старой systemd-установки)

**Экспорт на старом сервере:**
```
./scripts/export_old_zabbix_pg.sh --dir backups
```
**Восстановление:**  
Если используется контейнер Postgres — смотрите `scripts/restore_zabbix_pg.sh`.

---

## ⚠️ Если переменные окружения ZBX_TLS* игнорируются

Используйте override-файл конфига:
- Отредактируйте `conf/zabbix_server.extra.conf.example` и смонтируйте его как `/etc/zabbix/zabbix_server.conf` в `docker-compose.yml`, плюс параметры БД.
- Оставьте volume для сертификатов/ключей как в compose.

---

## 🔐 Безопасность

- Никогда не коммитьте `secrets/`, `.env`, приватные ключи и PSK-файлы.
- Устанавливайте `chmod 600` на приватные ключи и PSK.
- Меняйте PSK при необходимости.

---

## 📝 Примечания

- Все контейнеры объединены в одну сеть `zbx-net`.
- Для хранения данных Postgres используется volume `zbx-pgdata`.
- Сертификаты и ключи должны быть размещены в папке `secrets/` согласно структуре.
- Для работы с TLS (UI) используйте только актуальные сертификаты и ключи.
