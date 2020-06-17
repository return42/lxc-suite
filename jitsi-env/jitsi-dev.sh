#!/usr/bin/env bash
# -*- coding: utf-8; mode: sh indent-tabs-mode: nil -*-
# SPDX-License-Identifier: GNU General Public License v3.0 or later

[[ -z "${REPO_ROOT}" ]] &&  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

# shellcheck source=utils/lib.sh
source "${REPO_ROOT}/utils/lib.sh"

# https://stackoverflow.com/questions/32295168/make-jitsi-meet-work-with-apache-on-a-sub-url

jitsi_build_meet() {
    rst_title "build jitsi-meet"
    pushd ~/jitsi-meet  >/dev/null || die 43 "missing jitsi-meet clone"
    npm install
    make
    popd >/dev/null || die 43 "something went wrong"
}

jitsi_build_handbook() {
    rst_title "build jitsi-handbook"
    pushd ~/jitsi-handbook/website  >/dev/null || die 43 "missing jitsi-handbook clone"
    npm install
    echo "for live reloading use:: cd ~/jitsi-handbook/website; npm start"
    popd >/dev/null || die 43 "something went wrong"
}
