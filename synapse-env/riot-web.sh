# -*- coding: utf-8; mode: sh indent-tabs-mode: nil -*-
# SPDX-License-Identifier: GNU General Public License v3.0 or later
# shellcheck shell=bash

install_riot_web() {
    # https://github.com/vector-im/riot-web#getting-started

    local tar_name
    local tar_folder
    local nginx_static=/usr/share/nginx

    info_msg "install riot-web (${nginx_static}/riot-web)"
    tar_name="$(github_download_latest vector-im/riot-web riot .tar.gz)"
    tar_folder="${tar_name##*/}"
    tar_folder="${tar_folder%.tar.gz}"

    tar -xf "${tar_name}" --directory="${nginx_static}"
    rm -rf "${nginx_static}/riot-web"
    mv "${nginx_static}/${tar_folder}" "${nginx_static}/riot-web"
}

remove_riot_web() {

    local nginx_static=/usr/share/nginx

    info_msg "remove riot-web (${nginx_static}/riot-web)"
    rm -rf "${nginx_static}/riot-web"
}

riot_web_install_reverse_proxy() {

    info_msg "install reverse proxy (riot-web.conf)"
    install_template_src \
        --no-eval \
        "${SUITE_FOLDER}/riot-web.conf" \
        "${NGINX_APPS_AVAILABLE}/riot-web.conf" root root 644
    nginx_enable_app riot-web.conf
}

github_download_latest() {

    # usage::
    #
    #    github_download_latest <:user/:repo> <asset> <suffix>
    #

    #    $ tar_name=$(github_download_latest vector-im/riot-web riot .tar.gz)
    #    ...
    #    $ echo $tar_name
    #    /<...>/cache/riot-v1.6.2.tar.gz

    local repo="$1"
    local asset="$2"
    local suffix="$3"
    local fname

    tag_name=$(
        curl -s "https://api.github.com/repos/$1/releases/latest" \
            | python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["tag_name"]);'
            )

    fname="${asset}-${tag_name}${suffix}"
    cache_download \
        "https://github.com/${repo}/releases/download/${tag_name}/${fname}" \
        "${fname}"
    echo "${CACHE}/${fname}"
}
