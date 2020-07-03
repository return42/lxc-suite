# -*- coding: utf-8; mode: sh indent-tabs-mode: nil -*-
# SPDX-License-Identifier: GNU General Public License v3.0 or later
# shellcheck shell=bash

install_archlinux_build_suite(){
    local BUILD_FOLDER="${SERVICE_HOME}/build"

    pkg_install base-devel

    # In containers, we only have a root login, but 'makepkg' can't be
    # executed by root. 'makepkg' needs a build user with sudo rights and this
    # is where alle this hacking beginns:

    info_msg "activate wheel in /etc/sudoers"
    sed 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers > /etc/sudoers.new
    export EDITOR="cp /etc/sudoers.new"
    visudo
    rm /etc/sudoers.new
    usermod -aG wheel "${SERVICE_USER}"

    info_msg "prepare archlinux build environment: ${BUILD_FOLDER}"
    mkdir -p "${BUILD_FOLDER}"
    chown -R "${SERVICE_USER}:${SERVICE_USER}" "${BUILD_FOLDER}"

}

uninstall_archlinux_build_suite(){
    true  # nothing to do
}

archlinux_mod_authnz_pam(){
    # (archlinux) build & install apache mod_authnz_pam

    local BUILD_FOLDER="${SERVICE_HOME}/build/mod_authnz_pam"
    git_clone "https://github.com/return42/mod_authnz_pam.git" \
              "${BUILD_FOLDER}" master "${SERVICE_USER}"
    rst_title "build mod_authnz_pam package"
    echo
    tee_stderr 0.1 <<EOF | sudo -H -u "${SERVICE_USER}" -i 2>&1
cd "${BUILD_FOLDER}"
makepkg -s
EOF
    wait_key
    rst_title "install mod_authnz_pam package"
    _pushd "${BUILD_FOLDER}"
    pacman -U mod_authnz_pam*.pkg.tar.xz
    _popd
}
