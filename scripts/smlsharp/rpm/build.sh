#!/bin/sh
set -ex

#### the following must be given
test -n "$MVTH_FULL_VERSION"
test -n "$SMLSHARP_VERSION"
test -n "$OS_NAME"
test -n "$OS_VERSION"
test -n "$OS_ARCH"
test -n "$RPM_OS_ARCH"
test -n "$LLVM_VERSION"

#### install massivethreads
tar -xf "/build/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar"
rpm -i "massivethreads-$MVTH_FULL_VERSION.$RPM_OS_ARCH.rpm"
rpm -i "massivethreads-devel-$MVTH_FULL_VERSION.$RPM_OS_ARCH.rpm"

#### set up source tree
mkdir -p rpmbuild/SPECS rpmbuild/SOURCES
cd rpmbuild
cp /scripts/smlsharp/rpm/smlsharp.spec SPECS
cp "/build/smlsharp-$SMLSHARP_VERSION.tar.gz" SOURCES

#### doengrade llvm versions
case "$OS_NAME:$OS_VERSION" in
  almalinux:8|almalinux:9)
    (cd SPECS && patch -p0) < /scripts/smlsharp/rpm/spec-llvm.diff
    ;;
esac

#### build packages
rpmbuild -v -ba SPECS/smlsharp.spec

#### check packages
rpmlint RPMS/*/*.rpm SRPMS/*.rpm || :

#### output the result
find RPMS SRPMS -type f \
| tar -T - -cf "/build/smlsharp-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
      --transform='s,^.*/,,'
