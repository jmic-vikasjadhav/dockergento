#!/bin/bash
set -euo pipefail

source "$COMPONENTS_DIR"/input_info.sh
source "$COMPONENTS_DIR"/print_message.sh

sshHost="ssh.eu-3.magento.cloud"
sshUser=""
sqlHost="database.internal"
sqlUser="mysql"
sqlDb="main"
sqlPassword=""

print_info "Database transfer assistant: \n"

# Check php container
if [ -z "$(docker ps | grep phpfpm)" ]; then
    print_error "Error: PHP container is not running!\n"
    exit 1
fi

# Check mysql container
if [ -z "$(docker ps | grep db)" ]; then
    print_error "Error: Database container is not running!\n"
    exit 1
fi

for i in "$@"; do
    case $i in
    --ssh-host=*)
        sshHost="${i#*=}" && shift
        ;;
    --ssh-user=*)
        sshUser="${i#*=}" && shift
        ;;
    --sql-host=*)
        sqlHost="${i#*=}" && shift
        ;;
    --sql-user=*)
        sqlUser="${i#*=}" && shift
        ;;
    --sql-db=*)
        sqlDb="${i#*=}" && shift
        ;;
    --sql-password=*)
        sqlPassword="${i#*=}" && shift
        ;;
    -* | --* | *) ;;
    esac
done

# Request SSH credentials
read -r -p "Do you need to use SSH tunneling? [Y/n]: " sshTunnel
if [ -z "$sshTunnel" ] || [ "$sshTunnel" == "Y" ] || [ "$sshTunnel" == "y" ]; then
    read -p "SSH Host [Default: '${sshHost}']: " inputSshHost
    read -p "SSH User [Default: '${sshUser}']: " inputSshUser
    sshHost=${inputSshHost:-${sshHost}}
    sshUser=${inputSshUser:-${sshUser}}
else
    sshHost=""
    sshUser=""
fi

# Request Database credentials
read -p "Database Host [Default: '${sqlHost}']: " inputSqlHost
read -p "Database User [Default: '${sqlUser}']: " inputSqlUser
read -p "Database DB Name [Default: '${sqlDb}']: " inputSqlDb
read -p "Database Password [Default: '${sqlPassword}']: " inputSqlPassword
sqlHost=${inputSqlHost:-${sqlHost}}
sqlUser=${inputSqlUser:-${sqlUser}}
sqlDb=${inputSqlDb:-${sqlDb}}
sqlPassword=${inputSqlPassword:-${sqlPassword}}

# Prepare password
[ -z "$sqlPassword" ] && sqlPassword="" || sqlPassword="-p'$sqlPassword'"

# Request SSH credentials
read -r -p "Do you want to exclude 'core_config_data' table? [Y/n]: " sqlExclude
if [ -z "$sqlExclude" ] || [ "$sqlExclude" == "Y" ] || [ "$sqlExclude" == "y" ]; then
    sqlExclude=1
else
    sqlExclude=0
fi

print_info "You are going to transfer database from [${sshHost}:${sqlHost}] to [LOCALHOST].\n"
print_default "Press any key continue..."
read -r

# Check required data
if [ -z "$sqlHost" ] || [ -z "$sqlUser" ] || [ -z "$sqlDb" ]; then
    print_error "Error: Please enter all required data\n"
    exit 1
fi

print_info "Creating database dump from origin server...\n"

# Create database dump from origin server (WITHOUT SSH TUNNEL)
if [ -z "$sshHost" ]; then

    # Create dump into mysql container
    docker-compose exec db bash -c "mysqldump -h'$sqlHost' -u'$sqlUser' $sqlPassword $sqlDb | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | gzip -9 > /tmp/db.sql.gz"

# Create database dump from origin server (WITH SSH TUNNEL)
else

    # Create dump
    ssh ${sshUser}@${sshHost} "mysqldump -h'$sqlHost' -u'$sqlUser' $sqlPassword $sqlDb | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | gzip -9 > /tmp/db.sql.gz"

    # Download dump
    scp ${sshUser}@${sshHost}:/tmp/db.sql.gz .

    # Copy dump into mysql container
    docker cp db.sql.gz "$(docker-compose ps -q db | awk '{print $1}')":/tmp/db.sql.gz

fi

print_info "Restoring database dump into localhost...\n"

# Restore dump
[ $sqlExclude -eq 1 ] && docker-compose exec db bash -c "mysqldump -u\$MYSQL_USER -p\$MYSQL_PASSWORD \$MYSQL_DATABASE core_config_data > /tmp/ccd.sql 2> /dev/null"
docker-compose exec db bash -c "zcat /tmp/db.sql.gz | mysql -f -u\$MYSQL_USER -p\$MYSQL_PASSWORD \$MYSQL_DATABASE"
[ $sqlExclude -eq 1 ] && docker-compose exec db bash -c "[ -f /tmp/ccd.sql ] && mysql -f -u\$MYSQL_USER -p\$MYSQL_PASSWORD \$MYSQL_DATABASE < /tmp/ccd.sql"

# Reindex Magento
read -p "Do you want to reindex Magento? [Y/n]: " reindexMagento
if [ -z "$reindexMagento" ] || [ "$reindexMagento" == 'Y' ] || [ "$reindexMagento" == 'y' ]; then
    docker-compose exec phpfpm bin/magento indexer:reindex
fi

# Clear Magento cache
read -p "Do you want to clear Magento cache? [Y/n]: " clearMagento
if [ -z "$clearMagento" ] || [ "$clearMagento" == 'Y' ] || [ "$clearMagento" == 'y' ]; then
    docker-compose exec phpfpm bin/magento cache:flush
fi

print_info " All done!\n"
