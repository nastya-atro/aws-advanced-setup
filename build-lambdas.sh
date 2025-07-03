#!/bin/bash
# Этот скрипт автоматизирует сборку всех Lambda-функций в проекте.
# Он создает чистый каталог 'artifacts' для хранения готовых zip-архивов.

# Прерывать выполнение при любой ошибке для надежности
set -e

# --- Конфигурация (Совместимая с zsh/bash) ---
# Два отдельных массива для исходных кодов и имен артефактов.
# Убедитесь, что порядок элементов в обоих массивах совпадает!
SRC_DIRS=(
  "database"
  "check-lambdas/02-get-locations-handler"
  "check-lambdas/03-check-location-handler"
  "check-lambdas/04-send-notification-handler"
  "check-lambdas/01-notify-trigger-handler"
)
ZIP_FILES=(
  "db_migrator.zip"
  "GetLocationsHandler.zip"
  "CheckLocationHandler.zip"
  "SendNotificationHandler.zip"
  "NotifyTriggerHandler.zip"
)

# Имя каталога для артефактов
ARTIFACTS_DIR="artifacts"

# --- Логика Скрипта ---
echo "Starting Lambda build process..."

# Получаем абсолютный путь к каталогу скрипта
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ARTIFACTS_PATH="$SCRIPT_DIR/$ARTIFACTS_DIR"

# Очищаем и создаем каталог для артефактов
echo "Preparing artifacts directory: $ARTIFACTS_PATH"
rm -rf "$ARTIFACTS_PATH"
mkdir -p "$ARTIFACTS_PATH"

# Перебираем все определенные Lambda-функции по индексам
for i in "${!SRC_DIRS[@]}"; do
  SRC_DIR="${SRC_DIRS[$i]}"
  ZIP_FILE="${ZIP_FILES[$i]}"
  echo "--------------------------------------------------"
  echo "Processing Lambda: $SRC_DIR"

  # Переходим в каталог с исходным кодом
  cd "$SCRIPT_DIR/$SRC_DIR"

  # Проверяем, есть ли package.json и нужно ли устанавливать зависимости
  if [ -f "package.json" ]; then
    echo "Found package.json, installing production dependencies..."
    # Используем 'npm ci' для быстрой и чистой установки в CI/CD
    npm ci --only=production
  else
    echo "No package.json found, skipping dependency installation."
  fi

  # Архивируем содержимое каталога в папку с артефактами
  echo "Zipping source code into $ZIP_FILE..."
  # -r для рекурсивного обхода, -q для "тихого" режима
  zip -r -q "$ARTIFACTS_PATH/$ZIP_FILE" . -x "*.git*" "node_modules/aws-sdk/*"
  
  echo "Successfully built $ZIP_FILE"

  # Возвращаемся в исходный каталог
  cd "$SCRIPT_DIR"
done

echo "--------------------------------------------------"
echo "✅ All Lambdas built successfully in '$ARTIFACTS_DIR' directory." 