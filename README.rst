==========
LXC suites
==========

Managing LXC more comfortable in suites.  To get in use of LXC suite, lxd needs
to be installed on the HOST system first.

For usage run::

    ./utils/lxc.sh --help

To create your own LXC suite copy the default suite from ``./utils/lxc-dev.env``
into ``./my-lxc-suite.env`` and set the ``LXC_ENV`` variable in the
``./.config.sh``.

To run a command in all containers of the suite use ``cmd``::

    sudo -H ./utils/lxc.sh cmd -- ls -la

To run a command in one container replace ``--`` by container's name.  Eeach
container shares the root folder of the repository and the command
``utils/lxc.sh cmd`` **handles relative path names transparent**, compare output
of::

    $ sudo -H ./utils/lxc.sh cmd dev-archlinux ls -la README.rst
    INFO:  [dev-archlinux] ls -la README.rst

In the containers, you can run what ever you want, e.g. to start a bash use::

    $ sudo -H ./utils/lxc.sh cmd dev-archlinux bash
    INFO:  [dev-archlinux] bash
    [root@dev-archlinux lxc]#

If there comes the time you want to **get rid off all** the containers and
**clean up local images** just type::

  $ sudo -H ./utils/lxc.sh remove
  $ sudo -H ./utils/lxc.sh remove images
