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
