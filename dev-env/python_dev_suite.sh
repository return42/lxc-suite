# -*- coding: utf-8; mode: sh indent-tabs-mode: nil -*-
# SPDX-License-Identifier: GNU General Public License v3.0 or later
# shellcheck shell=bash

install_python_dev_suite(){
    case $DIST_ID-$DIST_VERS in
        ubuntu-*|debian-*)
            pkg_install build-essential python3-dev \
                        python3-pip python3-setuptools python3-venv
            ;;
        arch-*)
            pkg_install base-devel python python-pip \
                        python-setuptools python-virtualenv
            ;;
        fedora-*)
            pkg_install python3-virtualenv
            dnf groupinstall -y "Development Tools"
            ;;
        *)
            die 42 "$DIST_ID-$DIST_VERS: not yet implemented"
            ;;
    esac

    assert_user
    wait_key

    create_pyenv
    wait_key
    info_msg "install developer tools .."
    suite_service_user_shell <<EOF
pip install -U -r ${REPO_ROOT}/${LXC_SUITE_NAME}-env/py-req.txt
EOF
    info_msg "to start ptpython for this user use::"
    info_msg "    sudo -H ./utils/lxc.sh cmd $(hostname) sudo -u $SERVICE_USER -i ptpython"

    wait_key
}

uninstall_python_dev_suite(){

    userdel -r -f "${SERVICE_USER}" 2>&1 | prefix_stdout
}
