# -*- coding: utf-8; mode: sh indent-tabs-mode: nil -*-
# SPDX-License-Identifier: GNU General Public License v3.0 or later
# shellcheck shell=bash

# ----------------------------------------------------------------------------
# config
# ----------------------------------------------------------------------------

SERVICE_NAME="synapse"
SERVICE_USER="${SERVICE_USER:-${SERVICE_NAME}}"
SERVICE_HOME_BASE="${SERVICE_HOME_BASE:-/usr/local}"
SERVICE_HOME="${SERVICE_HOME_BASE}/${SERVICE_USER}"
SERVICE_GROUP="${SERVICE_USER}"
SERVICE_PYENV="${SERVICE_HOME}/pyenv"
LXC_SUITE_NAME="synapse"

# shellcheck source=base-env
source "${REPO_ROOT}/base-env"

# ----------------------------------------------------------------------------


suite_install(){
    # https://github.com/matrix-org/synapse/blob/master/INSTALL.md#platform-specific-instructions

    rst_title "Install suite: ${LXC_SUITE_NAME}"

    case $DIST_ID-$DIST_VERS in
        ubuntu-*|debian-*)
            pkg_install build-essential python3-dev libffi-dev \
                        python3-pip python3-setuptools sqlite3 \
                        libssl-dev python3-venv libjpeg-dev libxslt1-dev
            ;;
        arch-*)
            pkg_install base-devel python python-pip \
                        python-setuptools python-virtualenv sqlite3
            ;;
        fedora-*)
            pkg_install libtiff-devel libjpeg-devel libzip-devel freetype-devel \
                        libwebp-devel tk-devel redhat-rpm-config \
                        python3-virtualenv libffi-devel openssl-devel
            dnf groupinstall -y "Development Tools"
            ;;
        *)
            die 42 "$DIST_ID-$DIST_VERS: not yet implemented"
            ;;
    esac

    # make re-install and remove any previous installation

    info_msg "recreate system user (${SERVICE_USER})"
    userdel -r -f "${SERVICE_USER}" 2>&1 | prefix_stdout
    assert_user
    wait_key

    # https://github.com/matrix-org/synapse/blob/master/INSTALL.md#installing-from-source

    info_msg "install matrix-synapse"
    create_pyenv
    tee_stderr 0.1 <<EOF | sudo -H -u "${SERVICE_USER}" -i 2>&1 |  prefix_stdout "|$SERVICE_USER| "
pip install -U -r ${REPO_ROOT}/${LXC_SUITE_NAME}-env/py-req.txt
EOF
    wait_key

    rst_title "configure synapse homeserver.yaml" section
    tee_stderr 0.1 <<EOF | sudo -H -u "${SERVICE_USER}" -i 2>&1 |  prefix_stdout "|$SERVICE_USER| "
python -m synapse.app.homeserver \
  --server-name $(hostname) \
  --config-path homeserver.yaml \
  --generate-config \
  --report-stats=yes
synctl start
EOF
    wait_key
}


lxc_suite_info() {
    (
        lxc_set_suite_env
        cat <<EOF

Login as system user '$SERVICE_USER' and use::

  synctl --help

to manage the synapse homeserver.  Check (backup) the configuration files in
folder ${SERVICE_HOME}:

- synapse-archlinux.log.config
- synapse-archlinux.signing.key: Make a *safe* backup!

- homeserver.yaml; setup for a *test* environment::

    listeners:
      ...
      - port: 8008
        tls: false
        type: http
        x_forwarded: true
        bind_addresses: ['::', '0.0.0.0']
    ...
    resources:
      - names: [client, federation]
        compress: false

To start bash as '$SERVICE_USER'::

  ./${LXC_SUITE_NAME:-./suite <suite-name>} ${LXC_SUITE_IMAGE:-<image-name>} bash

        info_msg "to start python console use:: ./$LXC_SUITE_NAME ${LXC_SUITE_IMAGE:-<image-name>} bash"

To restart homeserver use::

  ./${LXC_SUITE_NAME:-./suite <suite-name>} ${LXC_SUITE_IMAGE:-<image-name>} synctl restart

Homeserver is listening on::

  http://$(primary_ip):8008

EOF

    )
}
