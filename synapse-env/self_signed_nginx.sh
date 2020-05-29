# -*- coding: utf-8; mode: sh indent-tabs-mode: nil -*-
# SPDX-License-Identifier: GNU General Public License v3.0 or later
# shellcheck shell=bash

install_self_signed_nginx() {

    if ! nginx_is_installe; then
        info_msg "Nginx is not installed."
        install_nginx
    fi
    _assert_cert
}

_assert_cert() {
    case $DIST_ID-$DIST_VERS in
        arch-*)
            if ! [[ -f /etc/nginx/ssl/server.key ]]; then
                info_msg "create missing key & cert at:  /etc/nginx/ssl/server.[key|crt]"
		mkdir -p /etc/nginx/ssl
		# shellcheck disable=SC2164
		cd /etc/nginx/ssl
		openssl req -new -x509 -nodes -newkey rsa:4096 -days 1095 \
			-keyout server.key \
			-out server.crt
		chmod 400 server.key
	        chmod 444 server.crt
            fi
            ;;
        *)
            die 42 "$DIST_ID-$DIST_VERS: not yet implemented"
            ;;
    esac
}
