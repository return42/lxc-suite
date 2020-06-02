# -*- coding: utf-8; mode: sh; indent-tabs-mode: nil -*-
# SPDX-License-Identifier: GNU General Public License v3.0 or later
# shellcheck shell=bash

nginx_static=/usr/share/nginx
NGINX_RIOT_SITE="riot-web.conf"

install_riot_web() {
    # https://github.com/vector-im/riot-web#getting-started

    local tar_name
    local tar_folder

    info_msg "install riot-web (${nginx_static}/riot-web)"
    tar_name="$(github_download_latest vector-im/riot-web riot .tar.gz)"
    tar_folder="${tar_name##*/}"
    tar_folder="${tar_folder%.tar.gz}"

    tar -xf "${tar_name}" --directory="${nginx_static}"
    rm -rf "${nginx_static}/riot-web"
    mv "${nginx_static}/${tar_folder}" "${nginx_static}/riot-web"

    info_msg "install riot-web config (config.json)"
    install_template_src \
        --no-eval \
        "${SUITE_FOLDER}/config.sample.json" \
        "${nginx_static}/riot-web/config.json" root root 644
    riot_web_config_init

    nginx_install_app "${NGINX_RIOT_SITE}"

}

remove_riot_web() {

    info_msg "remove riot-web (${nginx_static}/riot-web)"
    rm -rf "${nginx_static}/riot-web"
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

riot_web_config_init() {
    info_msg "init config: ${nginx_static}/riot-web/config.json"
    python <<EOF
import sys, json
with open('${nginx_static}/riot-web/config.json') as cfile:
    cfg = json.load(cfile)

cfg['default_server_config']['m.homeserver']['base_url'] = "https://$(primary_ip)"
cfg['default_server_config']['m.homeserver']['server_name'] = "$(primary_ip)"

with open('${nginx_static}/riot-web/config.json', 'w') as cfile:
    json.dump(cfg, cfile, indent=2, sort_keys=True)
EOF
}
