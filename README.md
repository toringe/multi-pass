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

You'll need a git server that will host the common GPG keyring and the common password-store. If you don't have an existing git server you can use, I've included basic documentation [below][2]. 


Once the git server is configured, you're ready to install the multi-user scripts.


Installation
------------

    git clone https://github.com/toringe/multi-pass.git
    cd multi-pass*

Edit the `pass.conf` configuration file if you don't like the default settings. You need to change this if you want to use a remote git server. When you're finished, start the installation script:

    ./install.sh

If no errors appeared, you're done! You may need to re-login to your account to activate gpg-agent and bash completion.


First user initialization
-------------------------

The first user has to initialize the password store and some other init stuff. So this user has to run:

    pass-new-user --init

The script will pause, then you, or someone with access, will need to add your ssh identity file to the `authorized_keys` file of the user running the git repository, so that you can push changes without having to enter your ssh password. When this has been done, the initial user need to press ENTER to continue the installation. The next and final step is to enter your own personal password that will be used to get access to the common password-store. 

NB! On idle servers, especially virtual ones, it may take considerable time to get enough entropy for the GPG key generation to complete. If this is the case, you may want to read the section "[Quick fix to increase entropy][3]" at the end of this document. Don't terminate the key generation, just open a new terminal and follow the quick fix steps.

Before any more users are added, you should populate the password-store with at least one entry. A new password can easily be generated:

    pass generate <hostname> <num>

Where `hostname` obviously is the hostname of the server you want to generate a common password. The `num` argument is a integer specifying the length of the password (number of characters). Once an entry has been made, sync the password store by executing:

    pass-sync
 

Normal usage
------------

When a new user (after the initial user) wants to join the common password store, this user runs:

    pass-new-user

Then, this script will pause, when the user's identity has to be added to the git server. This has to be done by someone with write permission to the git user's `authorized_keys` file. After the identity has been added, and the user has pressed ENTER, the user sets the password he/she wants to used to access the password store. The script will once again pause as an authorized user has to accept the new user by executing:

    pass-accept-user

After this, the new user can finish the registration by hitting ENTER. Then type

    pass

and observe that the password store has been populated with the current configuration. To access one of the passwords, type:

    pass <hostname>

In this setting, where you use the password store for passwords of different remote machines, you normally use it together with ssh. That's why I've added a ssh-wrapper to multi-pass, which uses pass transparently and with tab completion for the hostnames stored in the password-store.

    ssh-pass <hostname>

Type in your gpg password once (given that gpg-agent is working as it should) and it will use the long and awkward password stored without you even noticing it.


Setting up a local git server
-----------------------------

If you don't happen to have an existing git server, here is the basic documentation for getting a git server up and running on the same machine as you install multi-pass.

    sudo adduser --shell $(which git-shell) --gecos '' --disabled-password git
    sudo mkdir -p /home/git/.ssh
    sudo touch /home/git/.ssh/authorized_keys
    sudo cp -r /usr/share/doc/git/contrib/git-shell-commands /home/git/
    sudo chmod 750 /home/git/git-shell-commands/*
    sudo chmod 700 /home/git/.ssh
    sudo chmod 600 /home/git/.ssh/authorized_keys
    sudo chown -R git:git /home/git/

Then we initialze the repos we need. Here I'm using the default values from `pass.conf`.

    sudo -u git mkdir -p /home/git/repo/keyring.git /home/git/repo/pass-store.git
    sudo -u git git --git-dir=/home/git/repo/keyring.git/ init --bare
    sudo -u git git --git-dir=/home/git/repo/pass-store.git/ init --bare

Add your identity to git's `authorized_keys` file:

    cat $HOME/.ssh/id_rsa.pub | sudo tee -a /home/git/.ssh/authorized_keys

If everything works, the following command should output a listing of the two repos you created:

    ssh git@localhost list
    repo/keyring.git
    repo/pass-store.git

Quick fix to increase entropy
-----------------------------

Your system has run out of random bytes, and waits for the entropy to increase. This is a usual case for servers with no special hardware, and even more so for virtual servers. On a desktop, the kernel will seed its entropy from i/o sources like keyboard and mouse, in addition to disk and network, and usually have more "available" randomness. 

If you are less conserned about the insecurity of using poor randomness, the quick fix is:

    sudo apt-get install rng-tools
    sudo rngd -r /dev/urandom

And voila!, lots of poorly pseudo random bytes to choose from. But hey, it works!

[1]: http://www.passwordstore.org/
[2]: https://github.com/toringe/multi-pass#setting-up-a-local-git-server
[3]: https://github.com/toringe/multi-pass#quick-fix-to-increase-entropy
