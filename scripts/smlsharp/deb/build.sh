#!/bin/sh
set -ex
export TZ=UTC-9

#### the following must be given
test -n "$MVTH_FULL_VERSION"
test -n "$SMLSHARP_VERSION"
test -n "$SMLSHARP_BASE_VERSION"
test -n "$SMLSHARP_FULL_VERSION"
test -n "$OS_NAME"
test -n "$OS_VERSION"
test -n "$OS_ARCH"
test -n "$LLVM_VERSION"

#### expand source package
SMLSHARP_VERSION_DEBIAN=${SMLSHARP_FULL_VERSION%-*}
SRCDIR="smlsharp-$SMLSHARP_VERSION"
DEBDIR="$SRCDIR/debian"
tar -xf "/build/smlsharp-$SMLSHARP_VERSION.tar.gz"
cp "/build/smlsharp-$SMLSHARP_VERSION.tar.gz" \
   "smlsharp_$SMLSHARP_VERSION_DEBIAN.orig.tar.gz"
tar -C /tmp -xf "/build/smlsharp_$SMLSHARP_BASE_VERSION.deb-src.tar"
tar -C "$SRCDIR" -Jxf "/tmp/smlsharp_$SMLSHARP_BASE_VERSION.debian.tar.xz"

#### install massivethreads
tar -C /tmp -xf "/build/massivethreads-${OS_NAME}-${OS_VERSION}-${OS_ARCH}.tar"
dpkg -i "/tmp/libmassivethreads0_${MVTH_FULL_VERSION}_${OS_ARCH}.deb"
dpkg -i "/tmp/libmassivethreads-dev_${MVTH_FULL_VERSION}_${OS_ARCH}.deb"

#### apply patches
(
  cd "$SRCDIR"
  patch -p0 < /scripts/smlsharp/deb/debian.diff
  patch -p0 < /scripts/smlsharp/deb/debian-changelog.diff
)

#### downgrade debhelper-compat if necessary
case "$OS_NAME:$OS_VERSION" in
  ubuntu:20.04)
    sed -i 's/debhelper-compat (= 13)/debhelper-compat (= 12)/' \
        "$DEBDIR/control"
    ;;
esac

#### downgrade LLVM
sed -i "s/llvm-19/llvm-$LLVM_VERSION/" "$DEBDIR/control" "$DEBDIR/rules"

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
    dch -v "$SMLSHARP_FULL_VERSION" -D "$DISTRIB" -u low -b \
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
tar -cf "/build/smlsharp-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" *
