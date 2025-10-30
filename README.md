# 🇷🇺 Zabbix 7.4 в Docker + PSK для агентов 🐳🔒

**Веб-интерфейс:** `yourdomain.com`  

---

## 📦 Состав проекта

- **База данных:** PostgreSQL 17 (контейнер)
- **Zabbix Server:** `zabbix/zabbix-server-pgsql:alpine-7.4-latest`
- **Zabbix Web:** `zabbix/zabbix-web-nginx-pgsql:alpine-7.4-latest`
- **Nginx:** TLS-терминация
- **PSK для агентов:** безопасное подключение через предварительно согласованный ключ (PSK)

## 📂 Структура проекта

```plaintext
.
├── conf/                      # Конфигурационные файлы
│   └── nginx/                 # Конфигурация Nginx
│       └── conf.d/           # Виртуальные хосты
│           └── zabbix.conf   # Конфиг для веб-интерфейса
├── secrets/                   # Секреты (не коммитить в Git!)
│   └── server/               # Сертификаты и ключи сервера
│       ├── server.crt.pem    # Сертификат сервера
│       ├── server.key.pem    # Приватный ключ сервера
│       └── server.fullchain.pem  # Полная цепочка сертификатов
├── tls/                      # Файлы для работы с TLS
│   └── openssl.conf         # Конфиг для генерации CSR
├── .env                      # Переменные окружения (локальный)
├── .env.example             # Пример переменных окружения
├── docker-compose.yml       # Конфигурация Docker-контейнеров
└── README.md                # Документация проекта
```

---

## 🚀 Начало работы

1. **Копирование и настройка переменных окружения:**

   ```shell
   cp .env.example .env
   # Укажите параметры БД и сервера в .env
   ```

2. **Настройка HTTPS для веб-интерфейса:**

   a. Создайте файл конфигурации `tls/openssl.conf`:

   ```ini
   # Конфиг уже подготовлен в файле tls/openssl.conf
   # Для изменения параметров отредактируйте значения в секциях:
   # - req_distinguished_name (C, ST, L, O, OU, CN)
   # - alt_names (DNS.*)
   ```

   > 💡 **Важно:** Обязательно измените значения в `openssl.conf` под ваши требования, особенно:
   > - Местоположение (ST, L)
   > - Организацию (O, OU)
   > - Доменные имена (CN и DNS.*)
   

   b. Сгенерируйте ключ и CSR:

   ```shell
   # 1. Создание приватного ключа (4096 бит)
   openssl genrsa -out secrets/server/server.key.pem 4096
   chmod 600 secrets/server/server.key.pem

   # 2. Создание CSR с использованием конфига
   openssl req -new \
     -key secrets/server/server.key.pem \
     -out tls/server.csr.pem \
     -config tls/openssl.conf

   # 3. Проверка CSR (опционально)
   openssl req -text -noout -verify -in tls/server.csr.pem
   ```

   c. После получения сертификата от УЦ:

   ```shell
   # Копирование сертификата и создание полной цепочки
   cp server.crt.pem secrets/server/server.crt.pem
   cat server.crt.pem chain.pem > secrets/server/server.fullchain.pem
   ```

   *Вариант с PFX-сертификатом:*

   ```shell
   # Извлечение из PFX
   openssl pkcs12 -in server.pfx -nocerts -nodes -out secrets/server/server.key.pem
   openssl pkcs12 -in server.pfx -clcerts -nokeys -out secrets/server/server.crt.pem
   openssl pkcs12 -in server.pfx -cacerts -nokeys -out chain.pem
   cat secrets/server/server.crt.pem chain.pem > secrets/server/server.fullchain.pem
   chmod 600 secrets/server/server.key.pem
   ```

3. **Создание PSK для агентов:**

   ```shell
   openssl rand -hex 32 > /opt/zabbix/ssl/zabbix_agentd.psk
   # или используйте свой путь, но не коммитьте этот файл!
   ```

4. **Запуск служб:**

   ```shell
   docker compose up -d
   ```

5. **Вход в веб-интерфейс:**  
   [https://yourdomain.com](https://yourdomain.com)

---

## 🖥️ Настройка агентов Zabbix

### Настройка PSK в веб-интерфейсе

В настройках хоста (Zabbix → **Узлы сети** → выберите хост → **Шифрование**):

- Подключения к узлу сети: **PSK**
- Идентификатор PSK: строка-идентификатор (например, `zabbix-psk`)
- PSK: содержимое файла `/opt/zabbix/ssl/zabbix_agentd.psk`

### Пример конфигурации агента (Linux)

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

- Не коммитьте в репозиторий файлы из папки `secrets/`, файл `.env` и PSK-файлы
- Устанавливайте разрешения `chmod 600` на приватные ключи и PSK
- Периодически обновляйте PSK для повышения безопасности
- Храните все сертификаты и ключи в папке `secrets/`
- Следите за сроком действия сертификатов для HTTPS

## 📝 Системная информация

- Контейнеры работают в изолированной сети `zbx-net`
- База данных хранится в томе `zbx-pgdata`
- Файлы PSK доступны только для чтения внутри контейнеров


