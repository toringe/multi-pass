#!/bin/bash
########################## Multi-user password-store ###########################
#                                                                              #
# pass-sync: Syncronize the password-store with the repository. This script    #
# ---------  may be execute reguarly, e.g. by cron.                            #
#                                                                              #
# Author: Tor Inge Skaar                                                       #
#                                                                              #
################################################################################

. /usr/local/bin/pass-common-func.sh

authorized "sync store"

echo "Syncronizing keyring"
cd $HOME/.gnupg
git fetch --all
check $? "Failed to fetch keyring from git"
git reset --hard origin/master

echo "Syncronizing password store"
cd ..
pass git pull --no-edit
pass git push

echo "All done!"
