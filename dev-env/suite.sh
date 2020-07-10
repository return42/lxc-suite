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
SERVICE_PYENV="${SERVICE_HOME}/pyenv"

LXC_SUITE_NAME="dev"
PUBLIC_URL="${PUBLIC_URL:-http://$(primary_ip)/}"

# shellcheck disable=SC2034
SUITE_FOLDER=$(dirname "${BASH_SOURCE[0]}")
export TEMPLATES="${SUITE_FOLDER}/templates"

# ----------------------------------------------------------------------------
# This file is a LXC suite.  It is sourced from different context, do not
# manipulate the environment directly, implement functions and manipulate
# environment only is subshells!
# ----------------------------------------------------------------------------

# shellcheck source=base-env
source "${REPO_ROOT}/base-env"

suite_install(){
    (
        # make re-install and remove any previous installation
        suite_uninstall
        assert_user

        case $DIST_ID-$DIST_VERS in
            ubuntu-*|debian-*)
                pkg_install build-essential python3-dev \
                            python3-pip python3-setuptools python3-venv \
                            emacs-nox
                ;;
            arch-*)
                pkg_install base-devel python python-pip \
                            python-setuptools python-virtualenv \
                            emacs-nox
                ;;
            fedora-*)
                pkg_install python3-virtualenv \
                            emacs-nox
                dnf groupinstall -y "Development Tools"
                ;;
            *)
                die 42 "$DIST_ID-$DIST_VERS: not yet implemented"
                ;;
        esac

        # shellcheck source=dev-env/python_dev_suite.sh
        source "${SUITE_FOLDER}/python_dev_suite.sh"
        install_python_dev_suite

    )
}

suite_uninstall(){
    (

        # shellcheck source=dev-env/python_dev_suite.sh
        source "${SUITE_FOLDER}/python_dev_suite.sh"
        uninstall_python_dev_suite
        userdel -r -f "${SERVICE_USER}" 2>&1 | prefix_stdout

    )
}
