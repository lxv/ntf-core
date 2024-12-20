#!/bin/bash

set -euxo pipefail

fetch_git() {
    local org=$1
    local repo=$2
    mkdir -p srcs

    if [ -z "${3:-}" ]
    then
        # Clone the latest 'main' branch if no specific release tag provided
        local branch="main"
        curl -SL "https://github.com/${org}/${repo}/archive/refs/heads/${branch}.tar.gz" | tar -xzC srcs/
        mv "srcs/${repo}-${branch}" "srcs/${repo}"
    else
        local tag=$3
        curl -SL "https://github.com/${org}/${repo}/archive/refs/tags/${tag}.tar.gz" | tar -xzC srcs/
        mv "srcs/${repo}-${tag}" "srcs/${repo}"
    fi
}

fetch_deps() {
    fetch_git bloomberg bde-tools 4.8.0.0
    fetch_git bloomberg bde 4.8.0.0
}

configure() {
    PATH="$PATH:$(realpath srcs/bde-tools/bin)"
    export PATH
    eval "$(bbs_build_env -u opt_64_cpp20)"
}

build_bde() {
    pushd srcs/bde
    bbs_build configure
    bbs_build build -j8
    bbs_build --install=/opt/bb --prefix=/ install
    popd

    # cleanup
    rm -rf src/bde
}

build() {
    build_bde
}

list_directory() {
    local path=${1}

    if [ -e "${path}" ]; then
        echo "Contents of ${path}:"
        ls -l ${path}
    fi
}

fetch_deps
configure
build
