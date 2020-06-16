# -*- coding: utf-8; mode: sh indent-tabs-mode: nil -*-
# SPDX-License-Identifier: GNU General Public License v3.0 or later
# shellcheck shell=bash

# ----------------------------------------------------------------------------
# config
# ----------------------------------------------------------------------------

SERVICE_NAME="dev-user"
SERVICE_USER="${SERVICE_USER:-${SERVICE_NAME}}"
SERVICE_HOME_BASE="${SERVICE_HOME_BASE:-/usr/local}"
SERVICE_HOME="${SERVICE_HOME_BASE}/${SERVICE_USER}"
SERVICE_GROUP="${SERVICE_USER}"

LXC_SUITE_NAME="jitsi"
PUBLIC_URL="${PUBLIC_URL:-http://$(primary_ip)/$LXC_SUITE_NAME/}"

# shellcheck disable=SC2034
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
        case $DIST_ID-$DIST_VERS in
            ubuntu-*|debian-*)
                pkg_install build-essential npm
                ;;
            arch-*)
                pkg_install base-devel npm
                ;;
            fedora-*)
                dnf groupinstall -y "Development Tools"
                pkg_install npm
                ;;
            *)
                die 42 "$DIST_ID-$DIST_VERS: not yet implemented"
                ;;
        esac

        assert_user
        wait_key

        rst_title "getting jitsi source"
        git_clone "https://github.com/jitsi/jitsi-meet" \
                  "${SERVICE_HOME}/jitsi-meet" master\
                  "${SERVICE_USER}"

        sudo -H -u "${SERVICE_USER}" -i <<EOF
source "${LXC_REPO_ROOT}/jitsi-env/jitsi-dev.sh"
jitsi_build
EOF
    )
}

suite_uninstall(){
    (
        FORCE_TIMEOUT=
        userdel -r -f "${SERVICE_USER}" 2>&1 | prefix_stdout
    )
}
