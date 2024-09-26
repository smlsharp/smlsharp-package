#!/bin/sh
set -ex
export TZ=UTC-9

#### the following must be given
test -n "$MVTH_BASE_VERSION"
test -n "$MVTH_FULL_VERSION"
test -n "$OS_NAME"
test -n "$OS_VERSION"
test -n "$OS_ARCH"

#### expand source package
SRCDIR="massivethreads-${MVTH_BASE_VERSION%-*}"
DEBDIR="$SRCDIR/debian"
tar -xf "/build/massivethreads_$MVTH_BASE_VERSION.deb-src.tar"
dpkg-source -x "massivethreads_$MVTH_BASE_VERSION.dsc"
rm -f "massivethreads_$MVTH_BASE_VERSION.debian.tar.xz"
rm -f "massivethreads_$MVTH_BASE_VERSION.dsc"

#### apply patches
(
  cd "$SRCDIR"
  patch -p0 < /scripts/massivethreads/deb/debian.diff
  patch -p0 < /scripts/massivethreads/deb/debian-changelog.diff
  cp /scripts/massivethreads/patches/* debian/patches
  for i in /scripts/massivethreads/patches/*; do patch -p1 < "$i"; done
)

#### downgrade debhelper-compat if necessary
case "$OS_NAME:$OS_VERSION" in
  ubuntu:20.04)
    sed -i 's/debhelper-compat (= 13)/debhelper-compat (= 12)/' \
        "$DEBDIR/control"
    ;;
esac

#### add a new entry to changelog if necessary
if [ " $OS_NAME:$OS_VERSION" != ' debian:sid' ]; then
  . /scripts/os_codename.sh
  os_codename
  case "$OS_NAME" in
    debian) DISTRIB=unstable ;;
    ubuntu) DISTRIB=$OS_CODENAME ;;
  esac
  MAINTAINER=$(sed '/^ -- /!d;s/^ -- //;s/  .*$//;q' "$DEBDIR/changelog")
  (
    cd "$SRCDIR"
    DEBEMAIL="$MAINTAINER" \
    dch -v "$MVTH_FULL_VERSION" -D "$DISTRIB" -u low -b \
        "Build for $OS_CODENAME."
  )
fi

#### build the source and binary package
(
  cd "$SRCDIR"
  debuild -S -uc -us -Zxz -d -sa --lintian-opts -i
  export DEB_BUILD_OPTIONS=noautodbgsym
  debuild -b -uc -us -jauto -r --lintian-opts -i
)

#### output the results
rm -rf "$SRCDIR"
tar -cf "/build/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" *
