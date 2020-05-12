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

To make use of the containers from the *suite*, you have to build the containers
initial.  But be warned, **this might take some time**::

  $ sudo -H ./utils/lxc.sh build

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

Makefile
========

There is also a wrapper for Makefile environment::

    include utils/makefile.include

By example::

    $ make
    targets:
      test - run tests
    options:
      make V=0|1 [targets] 0 => quiet build (default), 1 => verbose build
      make V=2   [targets] 2 => give reason for rebuild of target

    $ sudo -H ./utils/lxc.sh cmd dev-archlinux make
    targets:
      test - run tests
    options:
    LXC: running in container LXC_ENV_FOLDER=lxc/dev-archlinux/
      make V=0|1 [targets] 0 => quiet build (default), 1 => verbose build
      make V=2   [targets] 2 => give reason for rebuild of target



