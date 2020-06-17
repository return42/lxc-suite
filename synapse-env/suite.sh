# -*- coding: utf-8; mode: sh; indent-tabs-mode: nil -*-
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
PUBLIC_URL="${PUBLIC_URL:-https://$(primary_ip)/_matrix}"
RIOT_PUBLIC_URL="${RIOT_PUBLIC_URL:-https://$(primary_ip)/riot}"

SUITE_FOLDER=$(dirname "${BASH_SOURCE[0]}")
export TEMPLATES="${SUITE_FOLDER}/templates"
NGINX_SYNAPSE_SITE="matrix.conf"

# ----------------------------------------------------------------------------
# This file is a LXC suite.  It is sourced from different context, do not
# manipulate the environment directly, implement functions and manipulate
# environment only is subshells!
# ----------------------------------------------------------------------------

# shellcheck source=base-env
source "${REPO_ROOT}/base-env"

lxc_set_suite_env() {
    export LXC_HOST_PREFIX="${LXC_SUITE_NAME}"
    export LXC_SUITE=(
        # rolling releases see https://www.archlinux.org/releng/releases/
        "images:archlinux"     "archlinux"
    )
}

_create_key() {
    tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 32 | head -n 1
}

suite_install(){
    (
        rst_title "HTTPS (self-signed)"
        rst_para "Synapse installation starts with setting up a HTTPS service."
        wait_key
        # shellcheck source=synapse-env/self_signed_nginx.sh
        source "${SUITE_FOLDER}/self_signed_nginx.sh"
        install_self_signed_nginx
        wait_key

        rst_title "Installing synapse homeserver"
        # shellcheck source=synapse-env/synapse_homeserver.sh
        source "${SUITE_FOLDER}/synapse_homeserver.sh"
        install_synapse_homeserver
        wait_key

        rst_title "configure synapse (/etc/synapse/)" section
        rst_para "generate default config files"
        wai_key
        suite_service_user_shell <<EOF
python -m synapse.app.homeserver \
  --server-name $(hostname) \
  --config-path homeserver.yaml \
  --generate-config \
  --report-stats=yes
EOF
        mkdir -p "/etc/synapse"
        mv "${SERVICE_HOME}/synapse-archlinux.log.config" "/etc/synapse/log_config.yaml"
        mv "${SERVICE_HOME}/homeserver.yaml" "/etc/synapse/homeserver.yaml"

        rst_para "Install configuration files from templates"
        wait_key
        install_template --no-eval "/etc/synapse/log_config.yaml" root root 644
        install_template "/etc/synapse/homeserver.yaml" root root 644

        install_template /usr/lib/tmpfiles.d/synapse.conf root root 644
        systemd_install_service synapse /lib/systemd/system/synapse.service root root 644
        wait_key

        rst_title "Install .well-known/matrix/server"
        # https://github.com/matrix-org/synapse/blob/develop/docs/delegate.md#well-known-delegation
        mkdir -p /usr/share/nginx/.well-known/matrix
        echo "{ \"m.server\": \"${PUBLIC_URL}\" }" > /usr/share/nginx/.well-known/matrix/server

        rst_title "Install matrix reverse proxy"
        echo
        nginx_install_app "${NGINX_SYNAPSE_SITE}"
        wait_key

        rst_title "Install riot-web"
        echo
        # shellcheck source=synapse-env/riot-web.sh
        source "${SUITE_FOLDER}/riot-web.sh"
        install_riot_web
        wait_key

        rst_title "Create first account (admin)" section
        echo
        homeserver_create_admin_account
        wait_key

        rst_title "Synapse homeserver installed"
        echo
    )
}


suite_uninstall() {
    (
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

suite_commands() {
    local container="$LXC_HOST_PREFIX-$LXC_SUITE_IMAGE"
    case $1 in
        docs)
            synapse_docs
            [[ $LXC_SUITE_IMAGE != '<suite-image>' ]] \
                && lxc_exec_cmd \
                       "$container" "${LXC_REPO_ROOT}/utils/lxc.sh" \
                       __show suite 2>/dev/null
            ;;
        *)
            __suite_commands "$@"
            ;;
    esac
}


synapse_docs() {
    rst_title "Synapse suite"
    echo
    # shellcheck source=synapse-env/self_signed_nginx.sh
    source "${SUITE_FOLDER}/self_signed_nginx.sh"
    # shellcheck source=synapse-env/synapse_homeserver.sh
    source "${SUITE_FOLDER}/synapse_homeserver.sh"
    # shellcheck source=synapse-env/riot-web.sh
    source "${SUITE_FOLDER}/riot-web.sh"

    local cmd_prefix="./${LXC_SUITE_NAME:-./suite <suite-name>} ${LXC_SUITE_IMAGE:-<image-name>}"
    cat <<EOF
The synapse suite consits of:

- self-signed nginx HTTPS server (nginx.conf)
- synapse homeserver: https://github.com/matrix-org/synapse
- riot-web client: https://github.com/vector-im/riot-web
- nginx reverse proxy for the matrix homeserver (matrix.conf) and the riot-web
  client (riot-web.conf)

Check (and backup) homeserver's configuration files in folder ${SERVICE_HOME}:

- /etc/synapse/log_config.yaml
- /etc/synapse/homeserver.yaml
- /usr/local/synapse/synapse-archlinux.signing.key

Check (and backup) riot-web's configuration files in folder ${nginx_static}/riot-web:

- ${nginx_static}/riot-web/config.json

To start bash from system user '$SERVICE_USER' use::

  ${cmd_prefix} bash

To get homeserver status use systemctl::

  ${cmd_prefix} cmd systemctl status synapse
  ${cmd_prefix} cmd journalctl -xe

Homerserver log is available from::

  ${cmd_prefix} tail -f /usr/local/synapse/homeserver.log

To stop systemd service and start homeserver on command line::

  ${cmd_prefix} cmd systemctl stop synapse
  ${cmd_prefix} python -m synapse.app.homeserver --config-path=/etc/synapse/homeserver.yaml

If federation is enabled, test: https://federationtester.matrix.org
EOF
}


lxc_suite_info() {
    (
        FORCE_TIMEOUT=
        lxc_set_suite_env
        cat <<EOF

Synapse homeserver:
  - ${PUBLIC_URL}/static
  - ${PUBLIC_URL}/client/versions

Riot WEB client at:
  - ${RIOT_PUBLIC_URL}
EOF
    )
}
