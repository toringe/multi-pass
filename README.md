Multi-user password-store
=========================

This is a multi-user version of Pass - the standard unix password manager ([passwordstore.org][1]). It's a series of scripts that facilitate multi-user (even on multiple machines) access to one common password store. Each user will have his/her own password to access the store. New users can register for access by themselves, but an existing authorized user need to approve the registration before access is granted. Pass is already using GnuPG and Git, so this multi-user version simply builds on that.  


System prerequisites
--------------------

    sudo apt-get install make tree git gnupg2 pwgen gnupg-agent openssh-client

You can install `pass` from the Ubuntu repositories, but it's a bit outdated. The pass-website also contains documentation for other distributions as well. But, I recommend downloading the latest tarball:

    wget http://git.zx2c4.com/password-store/snapshot/password-store-1.6.3.tar.xz
    tar xf password-store*
    cd password-store*
    sudo make install


Installation
------------

    git clone https://github.com/toringe/multi-pass.git
    cd multi-pass*

Edit the `pass.conf` configuration file if you don't like the default settings. You need to change this if you want to use a remote git server. When you're finished, start the installation script:

    sudo ./install.sh

If no errors appeared, you're done! You may need to re-login to your account to activate gpg-agent and bash completion.


First user initialization
-------------------------

The first user has to initialize the password store and do some other first time stuff:

    pass-new-user --init

The script is quite verbose due to all the git action, but errors should be easy to spot. To complete the initialization, you should log out and then in again, to make sure the gpg-agent is started properly and that synchronization has been completed. If you have disabled the `AUTOSYNC` in `pass.conf`, you'll have to manually run `pass-sync`.

NB! On idle servers, especially virtual ones, it may take considerable time to get enough entropy for the GPG key generation to complete. If this is the case, you may want to read the section "[Quick fix to increase entropy][2]" at the end of this document. Don't terminate the key generation, just open a new terminal and follow the quick fix steps.

Now the store is ready to be populated with new entries:

    pass generate <hostname> <num>

Where `hostname` obviously is the hostname of the server you want to generate a common password. The `num` argument is an integer specifying the length of the password (number of characters). Once an entry has been made, sync the password store by manually running

    pass-sync


Normal usage
------------

When a new user (after the initial user) wants to join the common password store, this user runs:

    pass-new-user

After the user has set the password he/she wants to used to access the password store, the script will pause as an authorized user has to accept the new user by executing:

    pass-accept-user

After this, the new user can finish the registration by hitting ENTER. Then type

    pass

and observe that the password store has been populated with the current configuration. To access one of the passwords, type:

    pass <hostname>

In this setting, where you use the password store for passwords of different remote machines, you normally use it together with ssh. That's why I've added a ssh-wrapper to multi-pass, which uses pass transparently and with tab completion for the hostnames stored in the password-store.

    ssh-pass <hostname>

Type in your gpg password once (given that gpg-agent is working as it should) and it will use the long and awkward password stored without you even noticing it.


Quick fix to increase entropy
-----------------------------

Your system has run out of random bytes, and waits for the entropy to increase. This is a usual case for servers with no special hardware, and even more so for virtual servers. On a desktop, the kernel will seed its entropy from i/o sources like keyboard and mouse, in addition to disk and network, and usually have more "available" randomness. 

If you are less conserned about the insecurity of using poor randomness, the quick fix is:

    sudo apt-get install rng-tools
    sudo rngd -r /dev/urandom

And voila!, lots of poorly pseudo random bytes to choose from. But hey, it works!

[1]: http://www.passwordstore.org/
[2]: https://github.com/toringe/multi-pass#quick-fix-to-increase-entropy
