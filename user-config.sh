#!/bin/bash

NIXUSER="$(whoami)"
echo "Installing with the $NIXUSER"

echo "Setup locale"
echo "Europe/Stockholm" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata -y

echo "Setup virtualenvwrapper"
export WORKON_HOME=~/Envs
mkdir -p $WORKON_HOME
source /usr/local/bin/virtualenvwrapper.sh
mkvirtualenv $PROJECT_NAME


echo "export WORKON_HOME=~/Envs" >> .profile
echo "source /usr/local/bin/virtualenvwrapper.sh" >> .profile
echo "workon $PROJECT_NAME" >> .profile

cd synced && setvirtualenvproject && cd ..


