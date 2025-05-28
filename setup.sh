#!/bin/bash

set -e

# Load .env if exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Prompt for Magento keys if missing
if [ -z "$MAGENTO_PUBLIC_KEY" ]; then
  read -p "Enter Magento Public Key: " MAGENTO_PUBLIC_KEY
fi

if [ -z "$MAGENTO_PRIVATE_KEY" ]; then
  read -sp "Enter Magento Private Key: " MAGENTO_PRIVATE_KEY
  echo
fi

# Check other required vars (fail if missing)
required_vars=(
  DB_HOST
  DB_NAME
  DB_USER
  DB_PASSWORD
  BASE_URL
  ADMIN_FIRSTNAME
  ADMIN_LASTNAME
  ADMIN_EMAIL
  ADMIN_USERNAME
  ADMIN_PASSWORD
  SEARCH_ENGINE
  ELASTICSEARCH_HOST
  ELASTICSEARCH_PORT
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ Required variable $var is missing or empty in .env"
    exit 1
  fi
done

echo "🔑 Configuring composer authentication..."
composer config --global http-basic.repo.magento.com "$MAGENTO_PUBLIC_KEY" "$MAGENTO_PRIVATE_KEY"

if [ -f "app/etc/env.php" ]; then
    echo "⚠️ Magento already installed. Skipping installation."
else
    echo "🚀 Installing Magento..."

    composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition .

    echo "⚙️ Running Magento setup install..."

    php bin/magento setup:install \
        --base-url="$BASE_URL" \
        --db-host="$DB_HOST" \
        --db-name="$DB_NAME" \
        --db-user="$DB_USER" \
        --db-password="$DB_PASSWORD" \
        --admin-firstname="$ADMIN_FIRSTNAME" \
        --admin-lastname="$ADMIN_LASTNAME" \
        --admin-email="$ADMIN_EMAIL" \
        --admin-user="$ADMIN_USERNAME" \
        --admin-password="$ADMIN_PASSWORD" \
        --language=en_US \
        --currency=USD \
        --timezone=Asia/Kolkata \
        --use-rewrites=1 \
        --search-engine="$SEARCH_ENGINE" \
        --elasticsearch-host="$ELASTICSEARCH_HOST" \
        --elasticsearch-port="$ELASTICSEARCH_PORT"

    echo "✅ Magento installation complete."
fi

echo "🔧 Setting file permissions..."

find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
chown -R www-data:www-data .

echo "♻️ Cleaning cache and deploying static content..."
php bin/magento cache:clean
php bin/magento setup:di:compile
php bin/magento setup:static-content:deploy -f

echo "🎉 Magento setup finished successfully."
