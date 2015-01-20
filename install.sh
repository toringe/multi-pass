#!/bin/bash
########################## Multi-user password-store ###########################
#                                                                              #
# Installation script                                                          #
#                                                                              #
# Author: Tor Inge Skaar                                                       #
#                                                                              #
################################################################################

if [ -r pass.conf ]; then
  . pass.conf
else
  echo "File not found: pass.conf. (Run install.sh from top directory)"
  exit 1
fi
if [ -r pass-common-func.sh ]; then
  . pass-common-func.sh
else
  echo "File not found: pass-common-func.sh. (Run install.sh from top dir.)"
  exit 1
fi

test $EUID -eq 0
check $? "You need to run this script as root"

which pass > /dev/null
check $? "Missing password-store. Get latest version from passwordstore.org"

which gpg2 > /dev/null
check $? "Missing GnuPG. Run: sudo apt-get install gnupg2"

which gpg-agent > /dev/null
check $? "Missing GPG-Agent. Run: sudo apt-get install gnupg-agent"

which git > /dev/null
check $? "Missing Git. Run: sudo apt-get install git"

git --version | cut -d" " -f3 | cut -d. -f1,2 | awk '{if($1>="1.9") exit 0; else exit 1}'
check $? "Wrong Git version ($gitver). Requires Git version 1.9 and above"

which ssh > /dev/null
check $? "Missing SSH Client. Run: sudo apt-get install openssh-client"

echo "Dependency checks complete"

# Path to this script
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
check $? "Unable to determine source path of this script"

# Copy files to their install paths
cp $basedir/pass.conf $CONFDIR
check $? "Failed to copy file"
cp $basedir/profile-gpg-addition $CONFDIR
check $? "Failed to copy file"
cp $basedir/pass-new-user.sh $BINDIR/pass-new-user
check $? "Failed to copy file"
cp $basedir/pass-accept-user.sh $BINDIR/pass-accept-user
check $? "Failed to copy file"
cp $basedir/pass-del-user.sh $BINDIR/pass-del-user
check $? "Failed to copy file"
cp $basedir/pass-sync.sh $BINDIR/pass-sync
check $? "Failed to copy file"
cp $basedir/pass-common-func.sh $BINDIR
check $? "Failed to copy file"
cp $basedir/ssh-pass.completion.sh /etc/bash_completion.d/ssh-pass
check $? "Failed to copy file"
cp $basedir/ssh-pass.sh $BINDIR/ssh-pass
check $? "Failed to copy file"
echo "Files successfully copied"

# Set proper permissions
chmod 755 $BINDIR/pass-*
check $? "Failed to set permission"
chmod 755 $BINDIR/ssh-pass
check $? "Failed to set permission"
chmod 644 $BINDIR/pass-common-func.sh
check $? "Failed to set permission"
chmod 644 $CONFDIR/pass.conf
check $? "Failed to set permission"
chmod 644 $CONFDIR/profile-gpg-addition
check $? "Failed to set permission"
chmod 644 /etc/bash_completion.d/ssh-pass
check $? "Failed to set permission"
echo "Proper permissions set"

# Change to custom CONFDIR and BINDIR
sed -i "s#/usr/local/etc/pass.conf#${CONFDIR}pass.conf#" $BINDIR/pass-accept-user
check $? "Failed to add custom setting"
sed -i "s#/usr/local/etc/pass.conf#${CONFDIR}pass.conf#" $BINDIR/pass-new-user
check $? "Failed to add custom setting"
sed -i "s#/usr/local/etc/pass.conf#${CONFDIR}pass.conf#" $BINDIR/pass-del-user
check $? "Failed to add custom setting"
sed -i "s#/usr/local/etc/pass.conf#${CONFDIR}pass.conf#" $BINDIR/ssh-pass
check $? "Failed to add custom setting"
sed -i "s#/usr/local/etc/profile-gpg-addition#${CONFDIR}profile-gpg-addition#" $BINDIR/pass-new-user
check $? "Failed to add custom setting"
sed -i "s#/usr/local/bin/pass-common-func.sh#${BINDIR}pass-common-func.sh#" $BINDIR/pass-accept-user
check $? "Failed to add custom setting"
sed -i "s#/usr/local/bin/pass-common-func.sh#${BINDIR}pass-common-func.sh#" $BINDIR/pass-del-user
check $? "Failed to add custom setting"
sed -i "s#/usr/local/bin/pass-common-func.sh#${BINDIR}pass-common-func.sh#" $BINDIR/pass-new-user
check $? "Failed to add custom setting"
sed -i "s#/usr/local/bin/pass-common-func.sh#${BINDIR}pass-common-func.sh#" $BINDIR/pass-sync
check $? "Failed to add custom setting"
echo "Finished customization"

# Initialize git repos
mkdir -p $GITDIR
check $? "Failed to create $GITDIR"
cd $GITDIR
if [ -d $KEYREPO ]; then
  echo "Keyring repo ($GITDIR/$KEYREPO) already exist. Skipping initialization" 1>&2
else
  git init --bare --shared $KEYREPO
  check $? "Failed to init git repo $KEYREPO"
fi
if [ -d $PASSREPO ]; then
  echo "Password repo ($GITDIR/$PASSREPO) already exist. Skipping initialization" 1>&2
else
  git init --bare --shared $PASSREPO
  check $? "Failed to init git repo $PASSREPO" 
fi

# Setting shared group permissions
chgrp -R $SHAREDGROUP $KEYREPO $PASSREPO
check $? "Failed to set group permissions"

echo
echo "Installation complete!"
echo
echo "The first user should initialize the password store by running:"
echo 
echo "pass-new-user --init"
echo
