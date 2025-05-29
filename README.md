# 🧱 Magento 2 Docker Setup

This repository provides a Dockerized setup to run Magento 2 with a single command. It uses Docker Compose for managing containers and includes a `setup.sh` script for automated installation.

---

## 📦 Stack

- Magento 2 (Community Edition)
- Apache + PHP 8.2
- MySQL 8
- Elasticsearch
- Composer

---

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/ZOROOZZ/Magento
cd Magento
docker-compose up -d --build
bash setup.sh
```
---
```bash
2. Create and Configure .env File
Copy the example and edit:

bash
Copy
Edit
cp .env.example .env
nano .env
Required variables:
```
### 3.Configure Credentials via .env File
You can securely configure and manage your Magento project credentials by modifying the .env file. This includes database access, admin account details, and Magento Marketplace keys, allowing you to customize your environment without altering the main setup script.
```bash
MAGENTO_PUBLIC_KEY=
MAGENTO_PRIVATE_KEY=

DB_HOST=mysql
DB_NAME=magento
DB_USER=magento
DB_PASSWORD=magento

BASE_URL=http://localhost/

ADMIN_FIRSTNAME=Admin
ADMIN_LASTNAME=User
ADMIN_EMAIL=admin@example.com
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123

SEARCH_ENGINE=elasticsearch7
ELASTICSEARCH_HOST=elasticsearch
ELASTICSEARCH_PORT=9200
```
---
```bash
3. Make the Setup Script Executable
bash
Copy
Edit
chmod +x setup.sh
4. Build and Start Containers
bash
Copy
Edit
docker-compose up -d --build
5. Run Magento Setup Script
bash
Copy
Edit
./setup.sh
This script:

Installs Magento

Configures composer authentication

Waits for MySQL to be ready

Sets permissions

Disables two-factor authentication

Compiles code and deploys static content

🛠️ Useful Commands
Access Web Container
bash
Copy
Edit
docker exec -it web bash
Restart Services
bash
Copy
Edit
docker-compose restart
Stop All Services
bash
Copy
Edit
docker-compose down
📁 Directory Structure
bash
Copy
Edit
.
├── Dockerfile
├── docker-compose.yml
├── setup.sh
├── .env
└── magento-app/       # Magento files will be installed here
🧾 Notes
First-time setup requires Magento authentication keys.

Keys are saved in .env after the first prompt by setup.sh.

Magento will be accessible at: http://localhost/

🔒 Security Reminder
Never commit your .env file or Magento keys to a public repository.

👨‍💻 Maintainer
Your Name

yaml
Copy
Edit

---

Let me know if you want this as a downloadable file or want to customize project name, author, or repo
