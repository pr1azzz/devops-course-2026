# Конфигурация виртуальной машины devops-vm

## 1. Параметры машины
- ОЗУ: 4096 МБ
- Количество ядер: 2
- Объём диска: 25 ГБ (динамически расширяемый)
- Версия ОС: Ubuntu Server 24.04 LTS

## 2. Сетевые интерфейсы
- **Адаптер 1 (NAT)**: IP `10.0.2.15`, доступ в интернет через NAT.
- **Адаптер 2 (Host-only)**: IP `192.168.56.101`, доступ с хоста к веб-серверу и по DNS-имени `devops.local`.

## 3. Правило проброса портов
- Порт хоста: **2222**
- Порт гостя: **2222**
- Протокол: TCP
- Назначение: SSH-доступ с хоста

## 4. Учётные записи
- **student** (uid 1000): основной пользователь, член групп `student`, `sudo`. Аутентификация: пароль.
- **devops** (uid 1001): пользователь для администрирования, член группы `sudo`. Аутентификация: SSH-ключ `devops_vm`.

## 5. Служба SSH
- Порт: **2222**
- Конфигурационный файл: `/etc/ssh/sshd_config.d/99-hardening.conf`
- Изменённые директивы:
  - `Port 2222`
  - `PermitRootLogin no`
  - `PasswordAuthentication no`
  - `PubkeyAuthentication yes`
  - `PermitEmptyPasswords no`
  - `MaxAuthTries 3`
  - `LoginGraceTime 30`
  - `AllowUsers devops`
  - `X11Forwarding no`
  - `ClientAliveInterval 300`
  - `ClientAliveCountMax 2`
- Конфликтующий файл `50-cloud-init.conf`: строка `PasswordAuthentication yes` закомментирована.

## 6. Правила межсетевого экрана
- Политики по умолчанию: `deny incoming`, `allow outgoing`
- Правила:
  - `2222/tcp LIMIT` — SSH с ограничением частоты (rate-limit)
  - `80/tcp ALLOW` — HTTP
  - `443/tcp ALLOW` — HTTPS
- Логирование: `medium`

## 7. Снимки состояния
- **01-clean-install** — после установки Ubuntu Server и обновления.
- **02-keys-configured** — после настройки ключевой аутентификации.
- **03-ssh-hardened** — после hardening SSH.
## 8. Веб-сервер
- **Устанавливаемый пакет:** `nginx` (версия 1.24.0)
- **Путь к конфигурации ресурса:** `/etc/nginx/sites-available/devops-site` (симлинк в `/etc/nginx/sites-enabled/devops-site`)
- **Каталог ресурса:** `/var/www/devops-site`
- **Владелец каталога:** `devops:devops`
- **Права на каталог:** `755` (drwxr-xr-x)
- **Права на файлы:** `644` (-rw-r--r--)
- **Путь к сертификату:** `/etc/ssl/certs/devops.crt` (владелец `root`, права `644`)
- **Путь к закрытому ключу:** `/etc/ssl/private/devops.key` (владелец `root`, права `600`)
- **Команда формирования сертификата:**
  ```bash
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/devops.key \
    -out /etc/ssl/certs/devops.crt \
    -subj "/CN=devops.local" \
    -addext "subjectAltName=DNS:devops.local"
