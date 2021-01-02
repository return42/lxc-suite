.. SPDX-License-Identifier: GNU General Public License v3.0 or later

----

**LXC suites** // *Managing LXC more comfortable in suites*

----

|lxc-suite logo|

**LXC suites** helps you to organize your basic development and build tasks in
**L**\ inu\ **X** **C**\ ontainers / written in pure bash, except LXD_ no
knick-knack is needed :)

|License| |Issues|  |PR|  |commits|

----

.. contents:: Contents
   :depth: 2
   :local:
   :backlinks: entry

----

To get in use of *LXC suites*, lxd needs to be installed on the HOST system
first::

    $ sudo -H snap install lxd
    $ sudo -H lxd init --auto

    $ cd ~/Downloads
    $ git clone https://github.com/return42/lxc-suite.git
    $ cd lxc-suite

If you are in a hurry and just want to *play* with LXC suites, install the
*developer suite* into a archlinux container::

    $ ./dev install archlinux

To start a bash in the container which we have just created use::

    $ ./dev archlinux bash

Or start any other command::

    $ ./dev archlinux pwd
    INFO:  [dev-archlinux] export LXC_ENV=dev-env/suite.sh
    INFO:  [dev-archlinux] sudo -u dev-user -i bash -c "pwd"
    /usr/local/dev-user
    INFO:  [dev-archlinux] exit code (0) from sudo -u dev-user -i bash -c "pwd"

In the next step, take a look at `predefined suites`_ and for build hosts the
lxc_ command (*lxc-suite's porcelain*)  might be interesting.


.. _suite:

``./suite``
===========

The lxc_ script wraps all the basic LXC commands to work with lxc-suites
(*lxc-suite's porcelain* implemented in ``./utils/lxc.sh``).  For the work in
context of a *suite* there is another bash script named: ``./suite``::

    $ ./suite --help
    usage::
      suite <suite-name> <image-name> create
      suite <suite-name> <image-name> drop
      suite <suite-name> <image-name> { command .. }
    ...
    LXC suites:
      dev synapse ...

Mostly you will run the *suite* command by using one of the wrapper (`predefined
suites`_).  To **install** the **dev suite** into a **archlinux** image use the
``./dev`` wrapper::

    $ ./dev archlinux create

Please note; the image name is ``archlinux`` while the container name is
``dev-archlinux``.  The **dev suite** from the example above has created a
system account (``dev-user``).  To get an interactive bash for this account in
the ``dev-archlinux`` container use::

    $ ./dev archlinux bash
    INFO:  [dev-archlinux] export LXC_ENV=dev-env/suite.sh
    INFO:  [dev-archlinux] sudo -u dev-user -i bash -c "bash"
    [dev-user@dev-archlinux ~]$ pwd
    /usr/local/dev-user
    [dev-user@dev-archlinux ~]$ exit 42
    exit
    WARN:  [dev-archlinux] exit code (42) from sudo -u dev-user -i bash -c "bash"

To evaluate variables in the container **use single quotation marks**::

    $ ./dev archlinux 'echo $(hostname)'
    ...
    dev-archlinux

To get a bash for container's **root login** use::

    $ ./dev archlinux root
    INFO:  [dev-archlinux] export LXC_ENV=dev-env/suite.sh
    INFO:  [dev-archlinux] bash
    [root@dev-archlinux lxc-suite]# pwd
    /share/lxc-suite

To **install packages** from distribution's package manager (pacman, dnf, apt)
into a container, use command ``pkg-install``.  For example, to install the
popular editor emacs, type the following::

    $ ./dev archlinux pkg-install emacs-nox
    ...
    $ ./dev archlinux emacs .

To **run a command** in bash from root -- with ``./utils/lib.sh`` *sourced* --
use suite's subcommand ``cmd``.  By example you can use it in your scripts
running on the HOST system::

    $ ./dev archlinux cmd global_IPs
    eth0|10.174.184.189
    eth0|fd42:573b:e0b3:e97e:216:3eff:fe17:b48b
    ...
    $ echo "Hello, container's IP is: $(./dev archlinux cmd primary_ip)"
    ...
    Hello, container's IP is: 10.174.184.189


.. _predefined suites:

Predefined suites
=================

``./dev`` : ubu2004, fedora31, archlinux
-----------------------------------------

.. _dev-py-req: https://github.com/return42/lxc-suite/blob/master/dev-py-req.txt
.. _ptpython: https://github.com/prompt-toolkit/ptpython

Suite that assembles a developer environment, useful as template or for
DevOps prototyping.::

  ./dev archlinux create

Creates system account ``dev-user`` and builds a python virtualenv
``~/dev-user/pyenv`` with requirements dev-py-req_ installed .

- ptpython_ -- usage: ``./dev archlinux ptpython``
- bash (``dev-user``) -- usage: ``./dev archlinux bash``

Alternatively you can use lxc_ command, to build all containers in once use::

  LXC_ENV=./dev-env/suite.sh ./lxc build

and to install suite into all containers use::

  LXC_ENV=./dev-env/suite.sh ./lxc install suite

To drop all containers of this suite use::

  LXC_ENV=./dev-env/suite.sh ./lxc remove

``./synapse`` : archlinux
-------------------------

.. _synapse-py-req: https://github.com/return42/lxc-suite/blob/master/synapse-py-req.txt
.. _synapse: https://github.com/matrix-org/synapse

Suite for prototyping with a synapse_ *homeserver*.::

  ./dev archlinux create

Creates system account ``synapse`` and builds a python virtualenv
``~/synapse/pyenv`` with requirements from synapse-py-req_ installed.

- bash (``synapse``) -- usage: ``./dev archlinux bash``


``./jitsi`` : ubu2004, fedora31, archlinux
------------------------------------------

.. _jitsi projects: https://jitsi.org/projects/

Suite for developing within `jitsi projects`_, to create developer environment
for your prefered distribution use one of::

  ./dev archlinux ubu2004 create
  ./dev archlinux fedora31 create
  ./dev archlinux archlinux create

``./mod-authnz-pam`` : archlinux
------------------------------

.. _mod_authnz_pam: https://github.com/adelton/mod_authnz_pam

Suite to test mod_authnz_pam_::

  Apache module mod_authnz_pam serves as PAM authorization module,
  supplementing authentication done by other modules, for example
  mod_auth_kerb. It can also be used as a full Basic Authentication
  provider for testing purposes, running the [login, password]
  authentication through the PAM stack.

I had an `issue <https://github.com/adelton/mod_authnz_pam/issues/12>`_ with
mod_authnz_pam_, so I implemented this small suite to run some tests / usage::

  ./mod-authnz-pam archlinux create
  ./mod-authnz-pam archlinux -- test

.. _create new suites:

Create new suites
=================

To create your own LXC suite, copy the *developer* suite from ``./dev-env`` into
``./my-env`` and edit the ``suite.sh`` file to your needs.  For convenience
create a wrapper ``/my-suite``.::

    $ cp -r ./dev.env ./my-env
    $ cp ./dev ./my
    $ $EDITOR ./my-env/suite.sh

Don't forget to drop the files you do not need, e.g. delete the ``py-req.txt``
if your suite does not need such a requirements file.


.. _lxc:

``./lxc``
=========

.. hint::

   This is about ``./lxc`` from *LXC suites*, please do not confuse it with
   the original command ``lxc`` from the LXD (see `LXD cheat sheet`_).

For usage run::

    ./lxc --help

To make use of the containers from the *suite*, you have to build the containers
initial.  But be warned, **this might take some time**::

    # build default 'dev' suite (./dev-env/suite.sh)
    $ ./lxc build

    # build 'my' suite (./my-env/suite.sh)
    $ LXC_ENV=./my-env/suite.sh ./lxc build

Alternatively you can run the more convenient command: suite_.  To run a command
in all containers of the suite use ``cmd``::

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

.. hint::

   If FORCE_TIMEOUT_ environment is unset, the lxc command defaults to
   FORCE_TIMEOUT=0 (suitable for batch processing)


.. _Makefile:

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


.. _LXC_ENV_FOLDER:

``LXC_ENV_FOLDER``
==================

The environment variable ``LXC_ENV_FOLDER`` is a **relative path** name.  The
default is::

    LXC_ENV_FOLDER="lxc-env/$(hostname)/"

but only in containers, on the HOST system, the environment is **unset
(empty string)**::

    LXC_ENV_FOLDER=

The value is available in a Makefile_ by including ``makefile.include``::

    include utils/makefile.include
    ...
    BUILD_FOLDER=build/$(LXC_ENV_FOLDER)

This evaluates to::

    HOST                     --> BUILD_FOLDER=build/
    container: dev-archlinux --> BUILD_FOLDER=build/lxc-env/dev-archlinux/

In bash scripts *source* the bash library::

    source utils/lib.sh
    ...
    echo "build OK" > build/$(LXC_ENV_FOLDER)status.txt

This evaluates to::

    HOST                     --> echo "build OK" > build/status.txt
    container: dev-archlinux --> echo "build OK" > build/lxc-env/dev-archlinux/status.txt


.. _FORCE_TIMEOUT:

``FORCE_TIMEOUT``
=================

Scripts from the lxc-suites do often implement choices, asking you *"do you want
to do this or that?"*.  Those selections do also implement a forced default
answer.  To drive batch processing set environment to zero::

  export FORCE_TIMEOUT=0

which means that the default selection takes place after zero seconds.  Depends
on your use cases you can also set 5 seconds or more to intervene at some
points.  Unset (or empty) this environment to force a user interaction.  BTW: to
be unset *is the default of FORCE_TIMEOUT* :)

----

.. _LXD cheat sheet:

LXD cheat sheet
===============

.. _LXD: https://linuxcontainers.org/lxd/docs/master/
.. _nsenter: https://man7.org/linux/man-pages/man1/nsenter.1.html


``lxd --version``
  LXD version

``lxc remote list``
  List installed image servers

``lxc image list`` / ``lxc image list local:``
  List (local) cached images.

``lxc image list images: amd64``
  List images available on server ``images:`` filtered by ``amd64``.

Create new storage named *pool* using an existing directory
``/fast-volume/lxd-pool`` (driver: ``dir``)::

    sudo -H mkdir /fast-volume/lxd-pool
    sudo -H lxc storage create pool dir source=/fast-volume/lxd-pool

    sudo -H lxc storage list
    +---------+-------------+--------+------------------------------------------------+---------+
    |  NAME   | DESCRIPTION | DRIVER |                     SOURCE                     | USED BY |
    +---------+-------------+--------+------------------------------------------------+---------+
    | default |             | dir    | /var/snap/lxd/common/lxd/storage-pools/default | 8       |
    +---------+-------------+--------+------------------------------------------------+---------+
    | pool    |             | dir    | /fast-volume/lxd-pools                         | 0       |
    +---------+-------------+--------+------------------------------------------------+---------+


----

|gluten free|

.. |gluten free| image:: https://forthebadge.com/images/featured/featured-gluten-free.svg

.. |License| image:: https://img.shields.io/github/license/return42/lxc-suite?style=plastic
   :target: https://github.com/return42/lxc-suite/blob/master/LICENSE

.. |Issues| image:: https://img.shields.io/github/issues/return42/lxc-suite?color=yellow&label=issues
   :target: https://github.com/return42/lxc-suite/issues

.. |PR| image:: https://img.shields.io/github/issues-pr-raw/return42/lxc-suite?color=yellow&label=PR
   :target: https://github.com/return42/lxc-suite/pulls

.. |commits| image:: https://img.shields.io/github/commit-activity/y/return42/lxc-suite?color=yellow&label=commits
   :target: https://github.com/return42/lxc-suite/commits/master

.. |lxc-suite logo| image:: https://raw.githubusercontent.com/return42/lxc-suite/master/utils/lxc_logo.png
   :target: https://github.com/return42/lxc-suite/blob/master/README.rst
   :alt: LXC suites
