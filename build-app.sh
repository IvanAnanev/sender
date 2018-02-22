#!/bin/bash

# ------------------------------------------------------------------------------
# TODO: этот блок переедет в docker-entrypoint.sh

FLAG=Makefile

# Create user if none
if [[ "$APPUSER" ]]; then
  grep -qe "^$APPUSER:" /etc/passwd || useradd -m -r -s /bin/bash -Gwww-data -gusers -gsudo $APPUSER
fi

# Change user id to FLAG owner's uid
FLAG_UID=$(stat -c '%u' $FLAG)
if [[ "$FLAG_UID" ]] && [[ $FLAG_UID != $(id -u $APPUSER) ]]; then
  if [[ "$FLAG_UID" != "0" ]] ; then
    echo "Set uid $FLAG_UID for user $APPUSER"
    usermod -u $FLAG_UID $APPUSER
  fi
  echo "chown $APPUSER /home/app"
  chown -R $APPUSER /home/app
fi

# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# блок с копированием ключа
gosu $APPUSER mkdir /home/op/.ssh
gosu $APPUSER touch /home/op/.ssh/config
gosu $APPUSER printf "host git.it.tender.pro\n HostName git.it.tender.pro\n IdentityFile /home/op/.ssh/hook\n User git\n" >> /home/op/.ssh/config
gosu $APPUSER cp /hook /home/op/.ssh/hook
gosu $APPUSER ssh-keyscan git.it.tender.pro > /home/op/.ssh/known_hosts

# чистим deps
echo " * rm -rf deps"
gosu $APPUSER rm -rf deps

echo " * mix local.hex --force"
gosu $APPUSER mix local.hex --force
echo " * mix local.rebar --force"
gosu $APPUSER mix local.rebar --force
echo " * mix deps.get"
gosu $APPUSER mix deps.get
echo " * mix compile"
gosu $APPUSER mix compile
echo " * mix release --env=prod"
gosu $APPUSER mix release --env=prod
