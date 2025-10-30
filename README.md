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

2. **Генерация сертификата для веб-интерфейса:**

   ```shell
   # 1. Создаем приватный ключ
   openssl genrsa -out secrets/server/server.key.pem 2048
   chmod 600 secrets/server/server.key.pem

   # 2. Создаем CSR (на основе вашего конфига)
   openssl req -new -key secrets/server/server.key.pem \
     -out tls/server.csr.pem \
     -config tls/openssl.conf

   # После получения сертификата от CA:
   cp server.crt.pem secrets/server/server.crt.pem
   cat server.crt.pem chain.pem > secrets/server/server.fullchain.pem
   ```

   *Альтернативный вариант из PFX:*

   ```shell
   # Извлечение из PFX
   openssl pkcs12 -in server.pfx -nocerts -nodes -out secrets/server/server.key.pem
   openssl pkcs12 -in server.pfx -clcerts -nokeys -out secrets/server/server.crt.pem
   openssl pkcs12 -in server.pfx -cacerts -nokeys -out chain.pem
   cat secrets/server/server.crt.pem chain.pem > secrets/server/server.fullchain.pem
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



## 🔐 Безопасность

- Никогда не коммитьте `secrets/`, `.env`, приватные ключи и PSK-файлы
- Устанавливайте `chmod 600` на приватные ключи и PSK
- Периодически меняйте PSK для повышения безопасности
- Храните все сертификаты и ключи в папке `secrets/` согласно структуре
- Используйте только актуальные сертификаты для TLS-терминации в Nginx

## 📝 Примечания

- Все контейнеры объединены в одну сеть `zbx-net`
- Для хранения данных Postgres используется volume `zbx-pgdata`
- PSK-файлы должны быть защищены и доступны только необходимым пользователям
