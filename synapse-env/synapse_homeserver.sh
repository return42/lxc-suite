# -*- coding: utf-8; mode: sh; indent-tabs-mode: nil -*-
# SPDX-License-Identifier: GNU General Public License v3.0 or later
# shellcheck shell=bash

install_synapse_homeserver(){
    # https://github.com/matrix-org/synapse/blob/master/INSTALL.md#platform-specific-instructions

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

    info_msg "create system user (${SERVICE_USER})"
    assert_user
    wait_key

    # https://github.com/matrix-org/synapse/blob/master/INSTALL.md#installing-from-source

    info_msg "install matrix-synapse"
    create_pyenv
    suite_service_user_shell <<EOF
pip install -U -r ${REPO_ROOT}/${LXC_SUITE_NAME}-env/py-req.txt
EOF
}

remove_synapse_homeserver(){

    suite_service_user_shell <<EOF
synctl stop
EOF
    userdel -r -f "${SERVICE_USER}" 2>&1 | prefix_stdout
    info_msg "delete /etc/synapse/"
    rm -f "/etc/synapse/"
}

homeserver_create_admin_account() {

    _passwd='admin'

    if [[ $FORCE_TIMEOUT != 0 ]]; then
        while true; do
            read -r -s -p "Enter password for user 'admin': [admin]" _passwd
            echo
            read -r -s -p "validate password: [ENTER]" _passwd2
            echo
            if [[ "$_passwd" == "$_passwd2" ]]; then
                break
            fi
        done
    fi

    [[ -z $_passwd ]] && _passwd='admin'

    info_msg "register_new_matrix_user -u admin -p xxxx -a -c /etc/synapse/homeserver.yaml http://localhost:8008"
    sudo -H -u "${SERVICE_USER}" -i 2>&1 <<EOF | prefix_stdout "|$SERVICE_USER| "
register_new_matrix_user -u admin -p "${_passwd}" -a -c /etc/synapse/homeserver.yaml http://localhost:8008
EOF
}
