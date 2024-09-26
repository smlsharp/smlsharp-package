#!/bin/sh
set -ex

#### the following must be given
test -n "$MVTH_BASE_VERSION"

#### add deb-src to APT sources
sed '/Types:/s/deb/deb-src/' /etc/apt/sources.list.d/debian.sources \
    > /etc/apt/sources.list.d/deb-src.sources
apt-get update

#### download the source
apt-get source libmassivethreads0

#### check the version number
test -f "massivethreads_${MVTH_BASE_VERSION%-*}.orig.tar.gz"
test -f "massivethreads_${MVTH_BASE_VERSION}.dsc"
test -f "massivethreads_${MVTH_BASE_VERSION}.debian.tar.xz"

#### output the result
tar -cf "/build/massivethreads_$MVTH_BASE_VERSION.deb-src.tar" \
    "massivethreads_${MVTH_BASE_VERSION%-*}.orig.tar.gz" \
    "massivethreads_${MVTH_BASE_VERSION}.dsc" \
    "massivethreads_${MVTH_BASE_VERSION}.debian.tar.xz"
