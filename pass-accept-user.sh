#!/bin/bash
########################## Multi-user password-store ###########################
#                                                                              #
# pass-accept-user : Script to be run by an already authorized user to accept  #
# ----------------   a new user (initiated by running pass-new-user).          #
#                                                                              #
# Author: Tor Inge Skaar                                                       #
#                                                                              #
################################################################################

. /usr/local/etc/pass.conf
. /usr/local/bin/pass-common-func.sh

authorized "add user"

cd $HOME/.gnupg
git pull origin master
import=`gpg --import git-pubring.asc 2>&1 | grep 'imported$'`
newid=`echo "$import" | grep -oP '(?<=gpg: key\s)\w+'`
newuser=`echo "$import" | cut -d\" -f2`
test -n $newid
check $? "Unable to determine ID of new key. Try to run the following manually: gpg --import git-pubring.asc"

echo
echo "--------------------------------------------------------------------------"
echo 
gpg --list-keys --fingerprint $newid
echo "--------------------------------------------------------------------------"
read -p "Authorize this user for the password store? [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  gpg --delete-keys --batch --yes $newid
  echo "Terminated"
  exit 1
fi

echo "Adding new key ID ($newid) to gpg.conf"
sed -i "/^group ${PASSNAME}=/ s/$/ ${newid}/" gpg.conf
test `grep -c $newid gpg.conf` -gt 0
check $? "Failed to update group in gpg.conf"

echo "Syncronizing keyring"
git add gpg.conf
git commit -m "Added key id ($newid) to gpg.conf"
git push origin master

echo "Re-encrypting password store"
pass init $PASSNAME

echo "Syncronizing password store"
pass git push

newuser=`gpg --list-keys --with-colon $newid | grep pub | cut -d: -f10 | cut -d\< -f1`
echo
echo " ***********************************************************************"
echo 
echo "  User added: $newuser"
echo
echo "  Please notify this user that the process may proceed by hitting ENTER"
echo 
echo " ***********************************************************************"
echo
