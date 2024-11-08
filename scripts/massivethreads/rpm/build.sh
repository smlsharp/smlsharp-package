#!/bin/sh
set -ex

#### the following must be given
test -n "$MVTH_FULL_VERSION"
test -n "$OS_NAME"
test -n "$OS_VERSION"
test -n "$OS_ARCH"
test -n "$RPM_OS_ARCH"

#### set up source tree
MVTH_VERSION=${MVTH_FULL_VERSION%-*}
mkdir -p rpmbuild/SPECS rpmbuild/SOURCES
cd rpmbuild
cp /scripts/massivethreads/rpm/massivethreads.spec SPECS
cp "/build/massivethreads-$MVTH_VERSION.tar.gz" SOURCES/v${MVTH_VERSION}.tar.gz
cp /scripts/massivethreads/rpm/massivethreads-1.00-manpages.patch SOURCES

#### build packages
rpmbuild -v -ba SPECS/massivethreads.spec

#### check packages
rpmlint RPMS/*/*.rpm SRPMS/*.rpm || :

#### output the result
find RPMS SRPMS -type f \
| tar -T - -cf "/build/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
      --transform='s,^.*/,,'
