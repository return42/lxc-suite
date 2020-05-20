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
PUBLIC_URL="${PUBLIC_URL:-http://$(primary_ip):8008}"

SUITE_FOLDER=$(dirname "${BASH_SOURCE[0]}")

# ----------------------------------------------------------------------------
# This file is a LXC suite.  It is sourced from different context, do not
# manipulate the environment directly, implement functions and manipulate
# environment only is subshells!
# ----------------------------------------------------------------------------

# shellcheck source=base-env
source "${REPO_ROOT}/base-env"

suite_install(){
    (
        FORCE_TIMEOUT=

        # shellcheck source=dev-env/synapse_homeserver.sh
        source "${REPO_ROOT}/synapse-env/synapse_homeserver.sh"

        remove_synapse_homeserver
        install_synapse_homeserver

        rst_title "configure synapse homeserver.yaml" section

        tee_stderr 0.1 <<EOF | sudo -H -u "${SERVICE_USER}" -i 2>&1 |  prefix_stdout "|$SERVICE_USER| "
python -m synapse.app.homeserver \
  --server-name $(hostname) \
  --config-path homeserver.yaml \
  --generate-config \
  --report-stats=yes
EOF
        install_template_src \
            --no-eval \
            "${SUITE_FOLDER}/homeserver.yaml" \
            "${SERVICE_HOME}/homeserver.yaml" root root 644

        tee_stderr 0.1 <<EOF | sudo -H -u "${SERVICE_USER}" -i 2>&1 |  prefix_stdout "|$SERVICE_USER| "
        synctl start
EOF
    )
}

lxc_suite_info() {
    (
        FORCE_TIMEOUT=
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

  ${PUBLIC_URL}

EOF
        wait_key
    )
}