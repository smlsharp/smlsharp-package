#!/bin/sh
set -ex

#### the following must be given
test -n "$SMLSHARP_BASE_VERSION"

#### add deb-src to APT sources
sed '/Types:/s/deb/deb-src/' /etc/apt/sources.list.d/debian.sources \
    > /etc/apt/sources.list.d/deb-src.sources
apt-get update

#### download the source
apt-get source smlsharp

#### check the version number
test -f "smlsharp_$SMLSHARP_BASE_VERSION.debian.tar.xz"

#### output the result
tar -cf "/build/smlsharp_$SMLSHARP_BASE_VERSION.deb-src.tar" \
    "smlsharp_$SMLSHARP_BASE_VERSION.debian.tar.xz"
