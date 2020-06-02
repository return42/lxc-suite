# -*- coding: utf-8; mode: sh indent-tabs-mode: nil -*-
# SPDX-License-Identifier: GNU General Public License v3.0 or later
# shellcheck shell=bash

# https://github.com/matrix-org/synapse
# https://github.com/vector-im/riot-web

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
PUBLIC_URL="${PUBLIC_URL:-https://$(primary_ip)/_matrix/static/}"
RIOT_PUBLIC_URL="${RIOT_PUBLIC_URL:-https://$(primary_ip)/riot/}"

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

        rst_title "Install synapse homeserver"

        # shellcheck source=synapse-env/synapse_homeserver.sh
        source "${SUITE_FOLDER}/synapse_homeserver.sh"
        install_synapse_homeserver
        wait_key

        rst_title "configure synapse homeserver.yaml" section
        echo
        suite_service_user_shell <<EOF
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
synctl stop
synctl start
EOF
        wait_key

        rst_title "Install HTTPS (self-signed)"
        echo
        # shellcheck source=synapse-env/self_signed_nginx.sh
        source "${SUITE_FOLDER}/self_signed_nginx.sh"
        install_self_signed_nginx
        wait_key

        rst_title "Install matrix reverse proxy"
        echo
        homeserver_install_reverse_proxy
        wait_key

        rst_title "Install riot-web"
        echo
        # shellcheck source=synapse-env/riot-web.sh
        source "${SUITE_FOLDER}/riot-web.sh"
        install_riot_web
        riot_web_install_reverse_proxy
        wait_key

        rst_title "Create first account (admin)" section
        echo
        homeserver_create_admin_account
        wait_key
    )
}


suite_uninstall() {
    (
        FORCE_TIMEOUT=

        # shellcheck source=synapse-env/synapse_homeserver.sh
        source "${SUITE_FOLDER}/synapse_homeserver.sh"
        nginx_remove_app matrix.conf
        remove_synapse_homeserver

        # shellcheck source=synapse-env/riot-web.sh
        source "${SUITE_FOLDER}/riot-web.sh"
        nginx_remove_app riot-web.conf
        remove_riot_web

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
        bind_addresses: ['127.0.0.1']
    ...
    resources:
      - names: [client, federation]
        compress: false

To start bash as '$SERVICE_USER'::

  ./${LXC_SUITE_NAME:-./suite <suite-name>} ${LXC_SUITE_IMAGE:-<image-name>} bash

To restart homeserver use::

  ./${LXC_SUITE_NAME:-./suite <suite-name>} ${LXC_SUITE_IMAGE:-<image-name>} synctl restart

- homeserver is listening on: ${PUBLIC_URL}
- Riot WEB client at:         ${RIOT_PUBLIC_URL}

EOF
        wait_key
    )
}
