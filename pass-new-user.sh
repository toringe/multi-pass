#!/bin/bash
################################################################################
#                                                                              #
# pass-new-user: Add new user to common password store. This script will       #
# -------------  typically be run by the new user. It pauses when it needs     #
#                an authorized user to accept the new user's request           #
#                                                                              #
# Author: Tor Inge Skaar                                                       #
#                                                                              #
################################################################################

. /usr/local/etc/pass.conf
. /usr/local/bin/pass-common-func.sh

INIT=0
if [ "$1" == "--init" ]; then
  INIT=1
fi

default=`getent passwd $USER | cut -d ':' -f 5 | cut -d ',' -f 1`
read -p "Your full name please [$default]: " realname
realname=${realname:-$default}

default="$USER@$EMAILDOMAIN"
read -p "Your e-mail address [$default]: " email
email=${email:-$default}

echo "Checking environment"
test -n $HOME
check $? "The environment variable HOME is not set"

agentcheck=`ps -ef | grep $USER | grep -i [g]pg-agent | wc -l`
if [ $agentcheck -eq 0 ]; then
  echo "Adding GPG-Agent to your profile"
  cat /usr/local/etc/profile-gpg-addition >> $HOME/.profile
  check $? "Failed to append your profile configuration"

  echo "Reloading profile"
  . $HOME/.profile
  check $? "Something when wrong when trying to reload profile"
else
  echo "Seems like GPG-Agent is already added to your profile"
fi

if [ -r $HOME/.ssh/id_rsa ]; then
  echo "Identity file already exists"
else
  echo "Generating SSH keys for Git-server access"
  ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -q -N ""
  check $? "ssh-keygen failed to generate keys"
fi

ssh -q -o PasswordAuthentication=no -o StrictHostKeyChecking=no $GITUSER@$GITSERVER list > /dev/null
if [ $? -ne 0 ]; then
  echo
  echo " ***********************************************************************"
  echo
  echo "  Your systems administrator or any one with full access to:"
  echo "  $GITUSER@$GITSERVER "
  echo
  echo "  have to add your identity file:"
  echo "  ${HOME}/.ssh/id_rsa.pub "
  echo
  echo "  to the $GITUSER user's ~/.ssh/authorized_keys file"
  echo
  echo "  When this has been done, press ENTER to complete the setup."
  echo
  echo " ***********************************************************************"
  read -p ""

  ssh -q -o PasswordAuthentication=no -o StrictHostKeyChecking=no $GITUSER@$GITSERVER list > /dev/null
  if [ $? -ne 0 ]; then
    echo "Your identity has not yet been added to $GITUSER@$GITSERVER"
    echo "Maybe you hit enter too quickly :)"
    read -p "Type \"yes\" when you _know_ your identity has been added: " answer
    if [ "${answer,,}" = "yes" ]; then
      ssh -q -o PasswordAuthentication=no -o StrictHostKeyChecking=no $GITUSER@$GITSERVER list > /dev/null
      check $? "Nope! Still doesn't work. Get it fixed and then re-run this script"
    fi
  fi

fi

echo "Generating GPG keys"
prompt="Enter passphrase to protect your private key: "
while IFS= read -p "$prompt" -r -s -n 1 char
do
    if [[ $char == $'\0' ]]; then
        break
    fi
    prompt='*'
    password+="$char"
done
echo

tmpfile=$RANDOM
cat <<EOF | gpg2 --gen-key --batch > $tmpfile 2>&1
Key-Type: default
Subkey-Type: default
Name-Real: $realname
Name-Email: $email
Expire-Date: 0
Passphrase: $password
%commit
EOF
check $? "Error during key generation"
keyid=`grep -oP '(?<=gpg: key\s)\w+' $tmpfile`
rm $tmpfile
test -n $keyid
check $? "Failed to determine your new key ID"

if [ $INIT -eq 1 ]; then
  echo "Initializing keyring"
else
  echo "Syncronizing keyring"
fi
cd $HOME/.gnupg
git init
git config --global core.mergeoptions --no-edit
git config --global push.default simple
git config --global user.name "$realname"
git config --global user.email "$email"
cat <<EOF > .gitignore
random_seed
*~
*.gpg
.*
EOF
git remote add origin $GITUSER@$GITSERVER:$KEYREPO
if [ $INIT -eq 1 ]; then
  echo "trust-model always" > gpg.conf
  echo "group $PASSNAME=$keyid" >> gpg.conf
  gpg --export -a > git-pubring.asc
else
  git fetch --all
  git reset --hard origin/master
  test -r git-pubring.asc
  check $? "Failed to retrieve common keyring from git"
  gpg --import git-pubring.asc
  gpg --export -a > git-pubring.asc
fi
git add git-pubring.asc
git commit -m "Added key for $realname"
git push origin +master

if [ $INIT -eq 0 ]; then
  echo
  echo " ***********************************************************************"
  echo
  echo "  To proceed, an existing authorized user now has to run the following "
  echo "  command on their terminal:"
  echo "                              pass-accept-user"
  echo
  echo "  When this has been done, press ENTER to complete the setup."
  echo
  echo " ***********************************************************************"
  read -p ""

  echo "Syncronizing GPG configuration"
  git fetch --all
  git reset --hard origin/master
  grep $keyid gpg.conf
  if [ $? -ne 0 ]; then
    echo "Your key id was not found in synced gpg.conf"
    echo "Maybe you hit enter too quickly :)"
    read -p "Type \"yes\" when an authorized user has accepted you: " answer
    if [ "${answer,,}" = "yes" ]; then
      git fetch --all
      git reset --hard origin/master
      grep $keyid gpg.conf
      check $? "Doh!...ok, do it manually then!"
    fi
  fi
fi
cd ..

if [ $INIT -eq 1 ]; then
  echo "Initializing password store"
else
  echo "Syncronizing password store"
fi
pass init $PASSNAME
pass git init
pass git remote add origin $GITUSER@$GITSERVER:$PASSREPO
if [ $INIT -eq 1 ]; then
 pass git push --set-upstream origin +master
else 
  pass git pull --no-edit origin master
  pass git branch --set-upstream-to=origin/master master
fi
echo "All done!"


