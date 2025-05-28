#!/bin/bash

set -e

# Define Magento app directory inside repo
TARGET_DIR="$(pwd)/magento-app"

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

# Check required environment variables
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

# Prepare Magento app directory
if [ -d "$TARGET_DIR" ]; then
  echo "Cleaning Magento app folder: $TARGET_DIR"
  rm -rf "$TARGET_DIR"/* "$TARGET_DIR"/.??*
else
  echo "Creating Magento app folder: $TARGET_DIR"
  mkdir -p "$TARGET_DIR"
fi

# Wait for MySQL in the web container network
echo "⏳ Waiting for MySQL ($DB_HOST) to be available on port 3306..."

while ! docker exec web bash -c "nc -z $DB_HOST 3306"; do
  echo "Waiting for MySQL..."
  sleep 3
done

echo "✅ MySQL is available. Proceeding..."

# Run commands inside the web container

# Configure Composer Authentication
echo "🔑 Configuring composer authentication inside container..."
docker exec web composer config --global http-basic.repo.magento.com "$MAGENTO_PUBLIC_KEY" "$MAGENTO_PRIVATE_KEY"

# Check if Magento is already installed
if docker exec web test -f /var/www/html/app/etc/env.php; then
  echo "⚠️ Magento already installed inside container. Skipping installation."
else
  echo "🚀 Installing Magento inside container..."

  docker exec web composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition /var/www/html

  echo "⚙️ Running Magento setup install inside container..."

  docker exec web php /var/www/html/bin/magento setup:install \
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

echo "🔧 Setting file permissions inside container..."
docker exec web bash -c "find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +"
docker exec web bash -c "find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +"
docker exec web chown -R www-data:www-data /var/www/html

echo "🚫 Disabling Two-Factor Authentication modules..."
docker exec -u www-data -w /var/www/html web php bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth
docker exec -u www-data -w /var/www/html web php bin/magento module:disable Magento_TwoFactorAuth
echo "✅ Two-Factor Authentication disabled."


echo "♻️ Cleaning cache and deploying static content inside container..."
docker exec web php /var/www/html/bin/magento cache:clean
docker exec web php /var/www/html/bin/magento setup:di:compile
docker exec web php /var/www/html/bin/magento setup:static-content:deploy -f

echo "🎉 Magento setup finished successfully."
