# -*- coding: utf-8; mode: sh indent-tabs-mode: nil -*-
# SPDX-License-Identifier: GNU General Public License v3.0 or later
# shellcheck shell=bash

install_python_dev_suite(){
    info_msg "prepare python developer environment"

    create_pyenv
    wait_key
    info_msg "install developer tools .."
    suite_service_user_shell <<EOF
pip install -U -r ${REPO_ROOT}/${LXC_SUITE_NAME}-env/py-req.txt
EOF
    _cmd="./${LXC_SUITE_NAME} ${LXC_SUITE_IMAGE}"
    info_msg "to start ptpython for user $SERVICE_USER use::"
    info_msg "    $_cmd ptpython"

    wait_key
}

uninstall_python_dev_suite(){
    true  # nothing to do
}
