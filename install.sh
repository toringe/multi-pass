#!/bin/bash
########################## Multi-user password-store ###########################
#                                                                              #
# Installation script                                                          #
#                                                                              #
# Author: Tor Inge Skaar                                                       #
#                                                                              #
################################################################################

. pass.conf
. pass-common-func.sh

test `whoami` != "root"
check $? "You should not run this script as root, but rather as a user with sudo privs"

test `groups | grep -c sudo` -ne 0
check $? "It seems your user ($USER) is not permitted to sudo"

which pass > /dev/null
check $? "Missing password-store. Run: sudo apt-get install pass"

which gpg2 > /dev/null
check $? "Missing GnuPG. Run: sudo apt-get install gnupg2"

which gpg-agent > /dev/null
check $? "Missing GPG-Agent. Run: sudo apt-get install gnupg-agent"

which git > /dev/null
check $? "Missing Git. Run: sudo apt-get install git"

which ssh > /dev/null
check $? "Missing SSH Client. Run: sudo apt-get install openssh-client"

# Path to this script
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Copy file to their install paths
sudo cp $basedir/pass.conf $CONFDIR
sudo cp $basedir/profile-gpg-addition $CONFDIR
sudo cp $basedir/pass-new-user.sh $BINDIR/pass-new-user
sudo cp $basedir/pass-accept-user.sh $BINDIR/pass-accept-user
sudo cp $basedir/pass-del-user.sh $BINDIR/pass-del-user
sudo cp $basedir/pass-sync.sh $BINDIR/pass-sync
sudo cp $basedir/pass-common-func.sh $BINDIR
sudo cp $basedir/ssh-pass.completion.sh /etc/bash_completion.d/ssh-pass
sudo cp $basedir/ssh-pass.sh $BINDIR/ssh-pass

# Set proper permissions
sudo chmod 755 $BINDIR/pass-*
sudo chmod 755 $BINDIR/ssh-pass
sudo chmod 644 $BINDIR/pass-common-func.sh
sudo chmod 644 $CONFDIR/pass.conf
sudo chmod 644 $CONFDIR/profile-gpg-addition
sudo chmod 644 /etc/bash_completion.d/ssh-pass

# Change to custom CONFDIR and BINDIR
sudo sed -i "s#/usr/local/etc/pass.conf#${CONFDIR}pass.conf#" $BINDIR/pass-accept-user
sudo sed -i "s#/usr/local/etc/pass.conf#${CONFDIR}pass.conf#" $BINDIR/pass-new-user
sudo sed -i "s#/usr/local/etc/pass.conf#${CONFDIR}pass.conf#" $BINDIR/pass-del-user
sudo sed -i "s#/usr/local/etc/pass.conf#${CONFDIR}pass.conf#" $BINDIR/ssh-pass
sudo sed -i "s#/usr/local/etc/profile-gpg-addition#${CONFDIR}profile-gpg-addition#" $BINDIR/pass-new-user
sudo sed -i "s#/usr/local/bin/pass-common-func.sh#${BINDIR}pass-common-func.sh#" $BINDIR/pass-accept-user
sudo sed -i "s#/usr/local/bin/pass-common-func.sh#${BINDIR}pass-common-func.sh#" $BINDIR/pass-del-user
sudo sed -i "s#/usr/local/bin/pass-common-func.sh#${BINDIR}pass-common-func.sh#" $BINDIR/pass-new-user
sudo sed -i "s#/usr/local/bin/pass-common-func.sh#${BINDIR}pass-common-func.sh#" $BINDIR/pass-sync

echo
echo "Installation complete!"
echo
echo "The first user should initialize the password store by running:"
echo 
echo "pass-new-user --init"
echo
