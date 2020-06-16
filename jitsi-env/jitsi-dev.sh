#!/usr/bin/env bash
# -*- coding: utf-8; mode: sh indent-tabs-mode: nil -*-
# SPDX-License-Identifier: GNU General Public License v3.0 or later

[[ -z "${REPO_ROOT}" ]] &&  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

# shellcheck source=utils/lib.sh
source "${REPO_ROOT}/utils/lib.sh"

# https://stackoverflow.com/questions/32295168/make-jitsi-meet-work-with-apache-on-a-sub-url

jitsi_build() {
    rst_title "build jitsi (npm-install & make)"
    pushd ~/jitsi-meet  >/dev/null || die 43 "missing jitsi-meet clone"
    npm install
    make
}
