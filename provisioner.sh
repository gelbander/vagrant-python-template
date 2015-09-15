#!/bin/bash
sed -i 's/^mesg n$/tty -s \&\& mesg n/g' /root/.profile

# Edit the following
export PROJECT_NAME="projectname"
APP_DB_USER=test
APP_DB_PASS=test
APP_DB_NAME=test
PG_VERSION=9.3

# Install essential packages from Apt
echo " >>>>> Install essential packages from apt"
sudo apt-get update -y
apt-get upgrade -y

echo "Europe/Stockholm" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata -y
apt-get install python-dev -y
apt-get install wget curl -y
apt-get install language-pack-UTF-8 -y
apt-get install -y git
locale-gen UTF-8

# Install redis and config to start on upstart.
echo " >>>>> Install redis"
apt-get install redis-server tcl8.5 -y
update-rc.d redis-server disable
cp /home/vagrant/synced/config-files/redis-server.conf /etc/init/
sed -i 's/daemonize yes/daemonize no/g' /etc/redis/redis.conf

echo " >>>>> Python dev packages"
apt-get install -y python python-dev python-setuptools python3-dev
apt-get install -y build-essential autoconf libtool pkg-config python-opengl \
python-imaging python-pyrex python-pyside.qtopengl idle-python2.7 \
qt4-dev-tools qt4-designer libqtgui4 libqtcore4 libqt4-xml libqt4-test \
libqt4-script libqt4-network libqt4-dbus python-qt4 python-qt4-gl libgle3 \
libncurses5-dev libevent-dev libffi-dev libssl-dev libxml2-dev libxslt-dev
# Dependencies for image processing with Pillow (drop-in replacement for PIL)
# supporting: jpeg, tiff, png, freetype, littlecms
apt-get install libjpeg-dev libtiff-dev zlib1g-dev libfreetype6-dev -y
apt-get install libmemcached-dev liblcms2-dev -y


# Install pip and virtualenv etc.
echo " >>>>> Installing pip"
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py

echo " >>>>> Installing security dependencies"
pip install requests[security] --upgrade

echo " >>>>> Installing global packages for python"
pip install virtualenv virtualenvwrapper ipython ipdb

# User installations
echo " >>>>> User specific installations"
su -c "source /home/vagrant/synced/user-config.sh" vagrant

echo " >>>>> Start postgres install"
pip install psycopg2
apt-get install libpq-dev -y

print_db_usage () {
  echo "Your PostgreSQL database has been setup and can be accessed on your "
  echo "local machine on the forwarded port (default: 15432)"
  echo "  Host: localhost"
  echo "  Port: 15432"
  echo "  Database: $APP_DB_NAME"
  echo "  Username: $APP_DB_USER"
  echo "  Password: $APP_DB_PASS"
  echo ""
  echo "Admin access to postgres user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo ""
  echo "psql access to app database user via VM:"
  echo "  vagrant ssh"
  echo "  sudo su - postgres"
  echo "  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost $APP_DB_NAME"
  echo ""
  echo "Env variable for application development:"
  echo "  DATABASE_URL=postgresql://$APP_DB_USER:$APP_DB_PASS@localhost:15432/$APP_DB_NAME"
  echo ""
  echo "Local command to access the database via psql:"
  echo "  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost -p 15432 $APP_DB_NAME"
}

export DEBIAN_FRONTEND=noninteractive

PROVISIONED_ON=/etc/vm_provision_on_timestamp
if [ -f "$PROVISIONED_ON" ]
then
  echo "VM was already provisioned at: $(cat $PROVISIONED_ON)"
  echo "To run system updates manually login via 'vagrant ssh' and run "
  echo "'apt-get update && apt-get upgrade'"
  echo ""
  print_db_usage
  exit
fi

PG_REPO_APT_SOURCE=/etc/apt/sources.list.d/pgdg.list
if [ ! -f "$PG_REPO_APT_SOURCE" ]
then
  # Add PG apt repo:
  echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > "$PG_REPO_APT_SOURCE"

  # Add PGDG repo key:
  wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
fi

# Update package list and upgrade all packages
apt-get -y install "postgresql-$PG_VERSION" "postgresql-contrib-$PG_VERSION"

PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
PG_DIR="/var/lib/postgresql/$PG_VERSION/main"

# Edit postgresql.conf to change listen address to '*':
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

# Append to pg_hba.conf to add password auth:
echo "host    all             all             all            md5" >> "$PG_HBA"

# Explicitly set default client_encoding
echo "client_encoding = utf8" >> "$PG_CONF"

# Restart so that all new config is loaded:
service postgresql restart

cat << EOF | su - postgres -c psql
-- Create the database user:
CREATE USER $APP_DB_USER WITH PASSWORD '$APP_DB_PASS';

-- Create the database:
CREATE DATABASE $APP_DB_NAME WITH OWNER=$APP_DB_USER
                                  LC_COLLATE='en_US.utf8'
                                  LC_CTYPE='en_US.utf8'
                                  ENCODING='UTF8'
                                  TEMPLATE=template0;
EOF

# Tag the provision time:
date > "$PROVISIONED_ON"

echo "Successfully created PostgreSQL dev virtual machine."
echo ""
print_db_usage
