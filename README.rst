==========
LXC suites
==========

Managing LXC more comfortable in *suites*.  To get in use of *LXC suites*, lxd
needs to be installed on the HOST system first::

    $ sudo -H snap install lxd
    $ sudo -H lxd init --auto

For usage run::

    ./lxc --help

To create your own LXC suite, copy the default suite from ``./dev.env`` into
``./my-suite.env``.

To make use of the containers from the *suite*, you have to build the containers
initial.  But be warned, **this might take some time**::

    # build default dev.env suite
    $ ./lxc build

    # build my-suite.env
    $ LXC_ENV=./my-suite.env ./lxc build

Alternatively you can set the ``LXC_ENV`` variable in the ``./.config.sh``.  To
run a command in all containers of the suite use ``cmd``::

    ./lxc cmd -- ls -la README.rst

To run a command in one container replace ``--`` by container's name.  Eeach
container shares the root folder of the repository and the command
``./lxc.sh cmd`` **handles relative path names transparent**, compare output
of::

    $ ./lxc cmd dev-archlinux 'echo "inside container: $(date)" > $(hostname).out'
    ...
    $ cat dev-archlinux.out
    inside container: Sat May 16 12:36:30 UTC 2020

In the containers, you can run what ever you want, e.g. to start a bash use::

    $ ./lxc cmd dev-archlinux bash
    INFO:  [dev-archlinux] bash
    [root@dev-archlinux lxc-suite]#

If there comes the time you want to **get rid off all** the containers and
**clean up local images** just type::

    $ ./lxc remove
    $ ./lxc remove images


.. _makefile.include:

Makefile
========

There is also a wrapper for *Makefile* environment::

    include utils/makefile.include

The file is already included in the local ``./Makefile``.  By example; this is
what you see when running ``make`` on the HOST system::

    $ make
    targets:
      ...
    options:
      ...

Inside the container you will find an additional ``LXC: running in container
LXC_ENV_FOLDER=`` message::

    $ ./lxc cmd dev-archlinux make
    INFO:  [dev-archlinux] make
    targets:
      ...
    options:
      LXC: running in container LXC_ENV_FOLDER=lxc-env/dev-archlinux/
      ...
    INFO:  [dev-archlinux] exit code (0) from make


``LXC_ENV_FOLDER``
==================

The environment variable ``LXC_ENV_FOLDER`` is a relative path name.  The
default is::

    LXC_ENV_FOLDER="lxc-env/$(hostname)/"

but only in containers, on the HOST system, the environment is **unset
(empty string)**::

    LXC_ENV_FOLDER=

The value is available in `Makefiles (including makefile.include)
<makefile.include>`_::

    include utils/makefile.include
    ...
    BUILD_FOLDER=$(LXC_ENV_FOLDER)build/

In bash scripts *source* the bash library::

    source utils/lib.sh
    ...
    echo "build OK" > $(LXC_ENV_FOLDER)build/status.txt

