#!/usr/bin/env bash
set -uo pipefail

PASS=0; FAIL=0

check() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo " [OK]  $desc"
    ((PASS++))
  else
    echo " [FAIL] $desc (ожидалось: '$expected', получено: '$actual')"
    ((FAIL++))
  fi
}

echo "Аудит конфигурации: $(hostname -f), $(date '+%Y-%m-%d %H:%M')"

echo "[1] Служба SSH"
check "Вход от имени root запрещён" "no" "$(sudo sshd -T | awk '/^permitrootlogin/{print $2}')"
check "Парольная аутентификация отключена" "no" "$(sudo sshd -T | awk '/^passwordauthentication/{print $2}')"

# TODO 1: проверьте, что значение параметра port отлично от 22
PORT=$(sudo sshd -T | awk '/^port/{print $2}')
if [[ "$PORT" != "22" ]]; then
  echo " [OK]  Порт SSH нестандартный (получено: '$PORT')"
  ((PASS++))
else
  echo " [FAIL] Порт SSH нестандартный (получено: '$PORT', ожидалось: не 22)"
  ((FAIL++))
fi

# TODO 2: проверьте, что значение параметра maxauthtries равно 3
check "MaxAuthTries равен 3" "3" "$(sudo sshd -T | awk '/^maxauthtries/{print $2}')"

echo "[2] Межсетевой экран"
check "Межсетевой экран активен" "active" "$(sudo ufw status | awk '/^Status:/{print $2}')"

# TODO 3: проверьте, что политика по умолчанию для входящего трафика равна deny
# источник данных: sudo ufw status verbose | grep Default
DEFAULT_IN=$(sudo ufw status verbose | grep Default | awk -F'[ ,]+' '{print $2}')
check "Политика по умолчанию для входящего трафика: deny" "deny" "$DEFAULT_IN"

echo "[4] Веб-сервер"

# a) Синтаксис nginx
if sudo nginx -t > /dev/null 2>&1; then
    echo " [OK]  Конфигурация nginx корректна"
    ((PASS++))
else
    echo " [FAIL] Конфигурация nginx некорректна"
    ((FAIL++))
fi

# б) Срок действия сертификата (не менее 30 дней)
CERT_DAYS=30
if sudo openssl x509 -checkend $((CERT_DAYS * 86400)) -noout -in /etc/ssl/certs/devops.crt > /dev/null 2>&1; then
    echo " [OK]  Сертификат действителен более $CERT_DAYS дней"
    ((PASS++))
else
    echo " [FAIL] Сертификат истекает менее чем через $CERT_DAYS дней"
    ((FAIL++))
fi

# в) Нет файлов с правом записи для всех в каталоге ресурса
if [[ -z "$(sudo find /var/www/devops-site -perm -o+w 2>/dev/null)" ]]; then
    echo " [OK]  Нет файлов с правом записи для всех в /var/www/devops-site"
    ((PASS++))
else
    echo " [FAIL] Найдены файлы с правом записи для всех в /var/www/devops-site"
    ((FAIL++))
fi

# г) Права ключа 600
KEY_PERMS=$(sudo stat -c '%a' /etc/ssl/private/devops.key 2>/dev/null || echo "")
if [[ "$KEY_PERMS" == "600" ]]; then
    echo " [OK]  Права ключа TLS равны 600"
    ((PASS++))
else
    echo " [FAIL] Права ключа TLS не равны 600 (получено: '$KEY_PERMS')"
    ((FAIL++))
fi

echo "[3] Учётные записи"
awk -F: ' $3>=1000 && $3<65534 {printf " %s (uid=%s)\n",$1,$3}' /etc/passwd

echo "Пройдено: $PASS, не пройдено: $FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
