#!/usr/bin/env bash

# Доставка статического ресурса на devops-vm
# Использование: scripts/deploy.sh [--dry-run]

set -euo pipefail

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"
LOCAL_DIR="$(git rev-parse --show-toplevel)/site/"

# 1. Разбор аргумента --dry-run
DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
    echo "=== Режим пробного запуска (--dry-run) ==="
fi

# 2. Проверки по требованиям 4 и 5
if [[ ! -f "${LOCAL_DIR}index.html" ]]; then
    echo "Ошибка: файл ${LOCAL_DIR}index.html не найден. Доставка отменена." >&2
    exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Ошибка: в репозитории есть незафиксированные изменения. Доставка отменена." >&2
    exit 1
fi

# 3. Синхронизация каталога
echo "Синхронизация ${LOCAL_DIR} на ${REMOTE}:${REMOTE_DIR}..."
rsync -avz --delete --chmod=D755,F644 ${DRY_RUN} -e "ssh -o BatchMode=yes -o ConnectTimeout=5" "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}"

# 4. При --dry-run — завершение с кодом 0 без проверки доступности
if [[ -n "${DRY_RUN}" ]]; then
    echo "Пробный запуск успешно завершен. Изменения не внесены."
    exit 0
fi

# 5. Проверка доступности
echo "Проверка доступности ${SITE_URL}..."
if curl -fsS --cacert "${CA_CERT}" -o /dev/null "${SITE_URL}"; then
    echo "Успех! Ресурс доступен."
    echo "Доставленный коммит: $(git rev-parse --short HEAD)"
    exit 0
else
    echo "Ошибка: ресурс ${SITE_URL} недоступен после доставки." >&2
    exit 1
fi
