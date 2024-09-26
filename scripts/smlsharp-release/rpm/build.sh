#!/bin/sh
set -ex

#### the following must be given
test -n "$OS_NAME"
test -n "$OS_VERSION"

#### set up source tree
mkdir -p rpmbuild/SPECS rpmbuild/SOURCES
cd rpmbuild
cp "/scripts/smlsharp-release/rpm/smlsharp-release-$OS_NAME.spec" SPECS
cp "/scripts/smlsharp-release/rpm/smlsharp.repo.$OS_NAME" SOURCES
cp "/keys/signing-key-pub.asc" SOURCES/RPM-GPG-KEY-smlsharp

#### build packages
rpmbuild -v -ba "SPECS/smlsharp-release-$OS_NAME.spec"

#### check packages
rpmlint RPMS/*/*.rpm SRPMS/*.rpm || :

#### output the result
find RPMS SRPMS -type f \
| tar -T - -cf "/build/smlsharprelease-$OS_NAME-$OS_VERSION.tar" \
      --transform='s,^.*/,,'
