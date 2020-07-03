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
PUBLIC_URL="${PUBLIC_URL:-http://$(primary_ip)/$LXC_SUITE_NAME/}"

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
            arch-*)
                # shellcheck source=dev-env/archlinux_build_suite.sh
                source "${SUITE_FOLDER}/archlinux_build_suite.sh"
                install_archlinux_build_suite
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

        case $DIST_ID-$DIST_VERS in
            arch-*)
                # shellcheck source=dev-env/archlinux_build_suite.sh
                source "${SUITE_FOLDER}/archlinux_build_suite.sh"
                uninstall_archlinux_build_suite
                ;;
        esac

        userdel -r -f "${SERVICE_USER}" 2>&1 | prefix_stdout

    )
}

suite_commands_usage() {
    _cmd="./${LXC_SUITE_NAME} ${LXC_SUITE_IMAGE}"
    cat <<EOF
usage:
  $_cmd -- [docs|apache_auth_pam]

docs:  print documentation of the suite
apache_auth_pam: create HTTP share using mod_authnz_pam
EOF
}

apache_auth_pam_doc() {
    rst_title "cmd apache_auth_pam" section
    cat <<EOF

HTTP share using mod_authnz_pam
  - ${PUBLIC_URL}public
  - ${PUBLIC_URL}closed
EOF
}


suite_commands() {
    local container="$LXC_HOST_PREFIX-$LXC_SUITE_IMAGE"
    case $1 in
        docs)
            if [[ $LXC_SUITE_IMAGE != '<suite-image>' ]]; then
                rst_title "services of $container"
                lxc_exec_cmd \
                    "$container" "${LXC_REPO_ROOT}/utils/lxc.sh" \
                    __show suite 2>/dev/null
            fi
            apache_auth_pam_doc
            ;;
        apache_auth_pam)
            # this command has to be executed in the conatiner
            if ! in_container; then
                lxc_exec_cmd "$container" "./${LXC_SUITE_NAME} ${LXC_SUITE_IMAGE}" -- apache_auth_pam
            else
                apache_auth_pam
            fi
            ;;
        *)
            __suite_commands "$@"
            ;;
    esac
}


apache_auth_pam() {
    rst_title "Install apache & mod_authnz_pam"

    if ! apache_is_installed; then
        install_apache
    fi

    info_msg "create share folders in /share/WWW"
    mkdir -p /share/WWW/public-share
    mkdir -p /share/WWW/closed-share
    echo "This is a public share." > /share/WWW/public-share/README
    echo "This is a closed share, available to logined users." > /share/WWW/README
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
            # shellcheck source=dev-env/archlinux_build_suite.sh
            source "${SUITE_FOLDER}/archlinux_build_suite.sh"
            archlinux_mod_authnz_pam
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
            chgrp shadow  /etc/shadow
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
