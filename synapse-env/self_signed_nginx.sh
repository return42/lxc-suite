# -*- coding: utf-8; mode: sh; indent-tabs-mode: nil -*-
# SPDX-License-Identifier: GNU General Public License v3.0 or later
# shellcheck shell=bash

install_self_signed_nginx() {

    if ! nginx_is_installed; then
        info_msg "Nginx is not installed."
        install_nginx
    else
        info_msg "Nginx is already installed."
    fi
    nginx_include_apps_enabled "${NGINX_DEFAULT_SERVER}"
    _assert_cert

    info_msg "install: ${NGINX_DEFAULT_SERVER}"
    install_template --no-eval "${NGINX_DEFAULT_SERVER}" root root 644
    nginx_reload
}

_assert_cert() {
    case $DIST_ID-$DIST_VERS in
        arch-*)
            if ! [[ -f /etc/nginx/ssl/server.key ]]; then
                info_msg "create missing key & cert at:  /etc/nginx/ssl/server.[key|crt]"
                mkdir -p /etc/nginx/ssl
                # shellcheck disable=SC2164
                pushd /etc/nginx/ssl >/dev/null
                openssl req -new -x509 -nodes -newkey rsa:4096 -days 1095 \
                        -keyout server.key \
                        -out server.crt \
                        -batch
                chmod 400 server.key
                chmod 444 server.crt
                # shellcheck disable=SC2164
                popd >/dev/null
            else
                info_msg "cert already exists:  /etc/nginx/ssl/server.[key|crt]"
            fi
            ;;
        *)
            die 42 "$DIST_ID-$DIST_VERS: not yet implemented"
            ;;
    esac
}
