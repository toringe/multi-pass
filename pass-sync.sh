#!/bin/bash
########################## Multi-user password-store ###########################
#                                                                              #
# pass-sync: Syncronize the password-store with the repository. This script    #
# ---------  may be execute reguarly, e.g. by cron, or when users log in/out.  #
#                                                                              #
# Author: Tor Inge Skaar                                                       #
#                                                                              #
################################################################################

. /usr/local/bin/pass-common-func.sh

DEBUG=false
if [ "$1" = "--debug" ]; then
  DEBUG=true
  echo "DEBUG is set"
fi

cd $HOME

authorized "sync store" $DEBUG

echo "Syncronizing keyring"
cd $HOME/.gnupg
if $DEBUG; then
  git fetch --all
else
  git fetch --all > /dev/null 2>&1
fi
check $? "Failed to fetch keyring from git"
if $DEBUG; then
  git reset --hard origin/master
else
  git reset --hard origin/master > /dev/null 2>&1
fi
check $? "Failed to reset index and working tree"
if $DEBUG; then
  gpg --import git-pubring.asc
else
  gpg --import git-pubring.asc > /dev/null 2>&1
fi
check $? "Failed to import git-pubring.asc"
rm git-pubring.asc
check $? "Failed to remove git-pubring.asc"

echo "Syncronizing password store"
cd ..
if $DEBUG; then
  pass git pull --no-edit origin master
else
  pass git pull --no-edit origin master > /dev/null 2>&1
fi
check $? "Pass failed to pull from git repo"
if $DEBUG; then
  pass git push
else
  pass git push > /dev/null 2>&1
fi
check $? "Pass failed to push to get repo"
