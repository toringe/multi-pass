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

id | grep -qc $SHAREDGROUP
check $? "User must be a member of group '$SHAREDGROUP'"

default=`getent passwd $USER | cut -d ':' -f 5 | cut -d ',' -f 1`
read -p "Your full name please [$default]: " realname
realname=${realname:-$default}

default="$USER@$EMAILDOMAIN"
read -p "Your e-mail address [$default]: " email
email=${email:-$default}

echo "Checking environment"
test -n $HOME
check $? "The environment variable HOME is not set"
cd $HOME

agentcheck=`ps -ef | grep $USER | grep -i [g]pg-agent | wc -l`
if [ $agentcheck -eq 0 ]; then
  echo "Adding GPG-Agent to your profile"
  cat /usr/local/etc/profile-gpg-addition >> $HOME/.profile
  check $? "Failed to append your profile configuration"
else
  echo "Seems GPG-Agent is already added to your profile"
fi

unset password
unset verify
unset charcount
echo -n "Select passphrase to secure your multi-pass access: "
stty -echo
charcount=0
while IFS= read -p "$prompt" -r -s -n 1 char; do

    # Handle ENTER
    if [[ $char == $'\0' ]]; then
        break
    fi

    # Handle Backspace
    if [[ $char == $'\177' ]]; then
        if [ $charcount -gt 0 ] ; then
            charcount=$((charcount-1))
            prompt=$'\b \b'
            password="${password%?}"
        else
            prompt=''
        fi
    else
        charcount=$((charcount+1))
        prompt='*'
        password+="$char"
    fi
done
stty echo
echo
echo -n "Type it again for verification: "
stty -echo
unset prompt
charcount=0
while IFS= read -p "$prompt" -r -s -n 1 char; do

    if [[ $char == $'\0' ]]; then
        break
    fi

    if [[ $char == $'\177' ]]; then
        if [ $charcount -gt 0 ] ; then
            charcount=$((charcount-1))
            prompt=$'\b \b'
            verify="${verify%?}"
        else
            prompt=''
        fi
    else
        charcount=$((charcount+1))
        prompt='*'
        verify+="$char"
    fi
done
stty echo
echo
test "$password" = "$verify"
check $? "The two inputs do not match each other!"

echo "Generating GPG keys (if it hangs, create some more entropy on the server)"
tmpfile=`mktemp`
cat <<EOF | gpg2 --gen-key --batch > $tmpfile 2>&1
Key-Type: default
Subkey-Type: default
Name-Real: $realname
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
git config --global user.name "$realname"
git config --global user.email "$email"
git config --global core.sharedRepository true
git config --global push.default current
git config --global core.mergeoptions --no-edit
cat <<EOF > .gitignore
random_seed
*~
*.gpg
.*
EOF
git remote add origin file://$GITDIR/$KEYREPO
if [ $INIT -eq 1 ]; then
  echo "trust-model always" > gpg.conf
  echo "group $PASSNAME=$keyid" >> gpg.conf
  git add gpg.conf
  git commit -m "Initial commit"
  git push origin master
  gpg --export -a > git-pubring.asc
  git add git-pubring.asc
  git commit -m "Added key for $realname"
  git push origin master
else
  git fetch --all
  git reset --hard origin/master
  test -r git-pubring.asc
  check $? "Failed to retrieve common keyring from git"
  gpg --import git-pubring.asc
  gpg --export -a > git-pubring.asc
  git add git-pubring.asc
  git commit -m "Added key for $realname"
  git push origin master
fi

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
      check $? "Doh!...still not found! You'll have to find out whats wrong!"
    fi
  fi
fi
cd ..

if [ $INIT -eq 1 ]; then
  echo "Initializing password store"
else
  echo "Synchronizing password store"
fi
source $HOME/.profile
pass init $PASSNAME
pass git init
pass git remote add origin file://$GITDIR/$PASSREPO
if [ $INIT -eq 1 ]; then
 pass generate .init 1 > /dev/null 2>&1
 pass git push origin master
else 
  pass git pull --no-edit origin master
  pass git branch origin master
fi

if $AUTOSYNC; then
  echo "Enabling synchronization at login and logout"
  echo -e "# Run pass-sync on login\npass-sync" >> $HOME/.profile
  echo -e "# Run pass-sync on logout\npass-sync" >> $HOME/.bash_logout
fi 

echo
echo " ***********************************************************************"
echo
echo "  Please log out and then in again to get gpg-agent running properly.   "
echo "  Alternatively re-source your profile manually.                        "
echo 
echo " ***********************************************************************"
echo
