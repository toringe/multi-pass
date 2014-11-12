########################## Multi-user password-store ###########################
#                                                                              #
# Common functions                                                             #
#                                                                              #
# Author: Tor Inge Skaar                                                       #
#                                                                              #
################################################################################

# Print message ($2) if exit code ($1) is not zero
function check {
  if [ $1 -ne 0 ]; then
    echo "$2" 1>&2;
    exit 1
  fi
}

# Check if password-store is encrypted with current user public key
# Which means user is authorized to accept and delete other users and sync
function authorized {
  prefix="Not authorized to $1"
  myid=`gpg --list-secret-keys | grep ssb | cut -d/ -f2 | cut -d" " -f1`
  test -n "$myid"
  check $? "$prefix (Couldn't determine your key id)"
  test -d $HOME/.password-store
  check $? "$prefix (No password store found)"
  afile=`find $HOME/.password-store/ -name *.gpg | head -1`
  test -r $afile
  check $? "$prefix (Unable to read file: $afile)"
  gpg --batch $afile 2>&1 | grep "encrypted with" | grep -q $myid
  check $? "$prefix (Store doesn't contain your key)"
}

