#!/bin/sh
# Fetch Packages needed
echo "Starting Initialization of CMaNGOS DB..."

# Prepare Databases
mysql -uroot -pmangos -e "create database tbccharacters;"
mysql -uroot -pmangos -e "create database tbclogs;"
mysql -uroot -pmangos -e "create database tbcmangos;"
mysql -uroot -pmangos -e "create database tbcrealmd;"
mysql -uroot -pmangos -e "create user 'mangos'@'%' identified by 'mangos';"
mysql -uroot -pmangos -e "grant all privileges on tbccharacters.* to 'mangos'@'%';"
mysql -uroot -pmangos -e "grant all privileges on tbclogs.* to 'mangos'@'%';"
mysql -uroot -pmangos -e "grant all privileges on tbcmangos.* to 'mangos'@'%';"
mysql -uroot -pmangos -e "grant all privileges on tbcrealmd.* to 'mangos'@'%';"

# Clone core code
echo "Core Version: ${ENV_CORE_COMMIT_HASH}"
git clone https://github.com/cmangos/mangos-tbc.git /tmp/cmangos
if [ "$ENV_CORE_COMMIT_HASH" != "HEAD" ]; then
  echo -e "Switching to Core Commit: ${ENV_CORE_COMMIT_HASH}\n"
  cd /tmp/cmangos
  git checkout ${ENV_CORE_COMMIT_HASH}
fi

# Clone db code
echo "DB Version: ${ENV_DB_COMMIT_HASH}"
git clone https://github.com/cmangos/tbc-db.git /tmp/db
if [ "$ENV_DB_COMMIT_HASH" != "HEAD" ]; then
  echo -e "Switching to DB Commit: ${ENV_DB_COMMIT_HASH}\n"
  cd /tmp/db
  git checkout ${ENV_DB_COMMIT_HASH}
fi

# Create default database structures
if [ -f /tmp/cmangos/sql/base/characters.sql ]; then
  mysql -uroot -pmangos tbccharacters < /tmp/cmangos/sql/base/characters.sql
fi

if [ -f /tmp/cmangos/sql/base/logs.sql ]; then
  mysql -uroot -pmangos tbclogs < /tmp/cmangos/sql/base/logs.sql
fi

if [ -f /tmp/cmangos/sql/base/mangos.sql ]; then
  mysql -uroot -pmangos tbcmangos < /tmp/cmangos/sql/base/mangos.sql
fi

if [ -f /tmp/cmangos/sql/base/realmd.sql ]; then
  mysql -uroot -pmangos tbcrealmd < /tmp/cmangos/sql/base/realmd.sql
fi

# Copy install script
cp -v /docker-entrypoint-initdb.d/InstallFullDB.config /tmp/db/InstallFullDB.config

# Set ADMINISTRATOR account to level 4 and lock it down
mysql -uroot -pmangos tbcrealmd -e 'UPDATE `account` SET gmlevel = "4", locked = "1" WHERE id = "1" LIMIT 1;'

# Remove other accounts
mysql -uroot -pmangos tbcrealmd -e 'DELETE FROM `account` WHERE id = "2" LIMIT 1;'
mysql -uroot -pmangos tbcrealmd -e 'DELETE FROM `account` WHERE id = "3" LIMIT 1;'
mysql -uroot -pmangos tbcrealmd -e 'DELETE FROM `account` WHERE id = "4" LIMIT 1;'

# Run install scripy
cd /tmp/db
./InstallFullDB.sh -World

# Cleanup
cd /
rm -rf /tmp/db
rm -rf /tmp/cmangos
