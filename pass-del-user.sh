#!/bin/bash
########################## Multi-user password-store ###########################
#                                                                              #
# pass-del-user: Removes a user from the common password store. This script    #
# -------------  can be run by any authorized user.                            #
#                                                                              #
# Author: Tor Inge Skaar                                                       #
#                                                                              #
################################################################################

. /usr/local/etc/pass.conf
. /usr/local/bin/pass-common-func.sh

cd $HOME

authorized "remove user"

read -p "Key ID of user to be removed: " keyid
test -n "$keyid"
check $? "No ID specified"

gpg --list-keys $keyid &>/dev/null
check $? "Key with ID $keyid was not found"

deluser=`gpg --list-keys --with-colon $keyid | grep pub | cut -d: -f10 | cut -d\< -f1`

read -p "Remove access to password store for $deluser [y/N]: " answer
if [ "${answer,,}" != "y" ]; then
  echo "Cancelled!"
  exit 1
fi

pass-sync

echo "Removing GPG key ($keyid) from keyring"
gpg --delete-keys --batch --yes $keyid

cd $HOME/.gnupg
echo "Removing GPG key from gpg.conf"
sed -i "s/ $keyid//g" gpg.conf

echo "Syncronizing keyring"
gpg --export -a > git-pubring.asc
git add git-pubring.asc gpg.conf
git commit -m "Removed key ($keyid)"
git push origin master
check $? "Something went wrong when pushing changes to the git repo"
cd ..

echo "Re-encrypting password store"
pass init $PASSNAME

echo "Syncronizing password store"
pass git push

echo
echo " ***********************************************************************"
echo 
echo "  User removed: $deluser"
echo
echo "  Please notify all remaining authorized users of the password store to"
echo "  re-initialize their local store. They should execute the following "
echo "  commands in their console:"
echo "                               pass-sync"
echo
echo " ***********************************************************************"
echo
