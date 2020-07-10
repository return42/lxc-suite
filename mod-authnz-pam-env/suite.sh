# -*- coding: utf-8; mode: sh indent-tabs-mode: nil -*-
# SPDX-License-Identifier: GNU General Public License v3.0 or later
# shellcheck shell=bash

# create HTTP share using mod_authnz_pam

SERVICE_NAME="user"
SERVICE_USER="${SERVICE_USER:-${SERVICE_NAME}}"
SERVICE_HOME_BASE="${SERVICE_HOME_BASE:-/home}"
SERVICE_HOME="${SERVICE_HOME_BASE}/${SERVICE_USER}"
SERVICE_GROUP="${SERVICE_USER}"
SERVICE_PYENV="${SERVICE_HOME}/pyenv"

# ----------------------------------------------------------------------------
# config
# ----------------------------------------------------------------------------

LXC_SUITE_NAME="mod-authnz-pam"
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

suite_test() {
    echo "run pamtest from root for test-user: ${SERVICE_USER}"
    pamtester www-login "$SERVICE_USER" authenticate

    echo "run pamtest from ${APACHE_SERVICE_USER} for test-user: ${SERVICE_USER}"
    sudo -u "${APACHE_SERVICE_USER}" pamtester www-login "$SERVICE_USER" authenticate

    echo "Testing apache <Location /public>"
    curl "${PUBLIC_URL}/public"

    echo "Testing apache <Location /closed>"
    curl -u "${SERVICE_USER}" "${PUBLIC_URL}/closed"
}

suite_install(){
    (
        # make re-install and remove any previous installation
        suite_uninstall
        info_msg "create user for the tests: $SERVICE_USER"
        useradd --home-dir "$SERVICE_HOME" "$SERVICE_USER"
        mkdir "$SERVICE_HOME"
        chown -R "$SERVICE_GROUP:$SERVICE_GROUP" "$SERVICE_HOME"
        groups "$SERVICE_USER"
        passwd "${SERVICE_NAME}"

        case $DIST_ID-$DIST_VERS in
            ubuntu-*|debian-*)
                # shellcheck disable=SC2086
                pkg_install build-essential curl $APACHE_PACKAGES
                ;;
            arch-*)
                # shellcheck disable=SC2086
                pkg_install base-devel curl $APACHE_PACKAGES
                # shellcheck source=mod-authnz-pam-env/archlinux_build_suite.sh
                source "${SUITE_FOLDER}/archlinux_build_suite.sh"
                install_archlinux_build_suite
                ;;
            fedora-*)
                # shellcheck disable=SC2086
                pkg_install curl $APACHE_PACKAGES
                dnf groupinstall -y "Development Tools"
                ;;
            *)
                die 42 "$DIST_ID-$DIST_VERS: not yet implemented"
                ;;
        esac
        apache_auth_pam
    )
}

suite_uninstall(){
    (
        case $DIST_ID-$DIST_VERS in
            arch-*)
                # shellcheck source=mod-authnz-pam-env/archlinux_build_suite.sh
                source "${SUITE_FOLDER}/archlinux_build_suite.sh"
                uninstall_archlinux_build_suite
                ;;
        esac
        userdel -r -f "${SERVICE_NAME}" 2>&1 | prefix_stdout
    )
}

lxc_suite_info() {
    (
        lxc_set_suite_env
        __lxc_suite_info
        local cmd_prefix="./${LXC_SUITE_NAME:-./suite <suite-name>} ${LXC_SUITE_IMAGE:-<image-name>}"
        cat <<EOF
HTTP share using mod_authnz_pam
  - ${PUBLIC_URL}public
  - ${PUBLIC_URL}closed
EOF
    )
}

apache_auth_pam() {
    rst_title "Install apache & mod_authnz_pam"

    if ! apache_is_installed; then
        install_apache
    fi

    info_msg "create share folders in /share/WWW"
    mkdir -p /share/WWW/public
    mkdir -p /share/WWW/closed
    echo "This is a public share." > /share/WWW/public/README
    echo "This is a closed share, users need to be logined." > /share/WWW/closed/README

    case $DIST_ID-$DIST_VERS in
        ubuntu-*|debian-*)
            chown -R www-data:www-data /share/WWW/
            # https://packages.ubuntu.com/xenial/libapache2-mod-authnz-pam
            pkg_install libapache2-mod-authnz-pam
            # /etc/apache2/mods-available/authnz_pam.conf
            a2enconf authnz_pam
            ;;
        arch-*)
            chown -R http:http /share/WWW/
            # shellcheck source=mod-authnz-pam-env/archlinux_build_suite.sh
            source "${SUITE_FOLDER}/archlinux_build_suite.sh"
            archlinux_mod_authnz_pam
            archlinux_pamtester
            ;;
        fedora-*)
            chown -R www-data:www-data /share/WWW/
            pkg_install mod_authnz_pam
            ;;
        *)
            err_msg "$DIST_ID-$DIST_VERS: apache not yet implemented"
            ;;
    esac

    info_msg "install PAM www-login"
    install_template --no-eval /etc/pam.d/www-login root root 644

    info_msg "install apache exp-imp.conf"
    apache_install_site --no-eval exp-imp.conf
    assert_pam_sugid_shadow
}

# PAM
# ---

assert_pam_sugid_shadow(){
    case $DIST_ID-$DIST_VERS in
        ubuntu-*|debian-*)
            info_msg "$DIST_ID-$DIST_VERS supports PAM sguid 'shadow' (nothing to do)"
            ;;
        arch-*)
            info_msg "$DIST_ID: adding PAM sguid 'shadow'"

            groupadd --system shadow
            chgrp shadow  /etc/gshadow
            chmod g+r /etc/gshadow
            chgrp shadow  /etc/shadow
            chmod g+r /etc/shadow

            # set-group-ID bit
            chgrp shadow  /sbin/unix_chkpwd
            chmod 02755   /sbin/unix_chkpwd
            if [[ -e /sbin/pam_extrausers_chkpwd ]]; then
                chgrp shadow  /sbin/pam_extrausers_chkpwd
                chmod 02755   /sbin/pam_extrausers_chkpwd
            fi
            ;;
        fedora-*)
            warn_msg "$DIST_ID-$DIST_VERS: PAM sguid 'shadow' not yet tested!?!?"
            ;;
        *)
            err_msg "$DIST_ID-$DIST_VERS: PAM sguid 'shadow' not yet implemented"
            ;;
    esac
}
