#!/bin/sh
export TZ=UTC-9
base=`dirname $0`
host="$base/../.."
dist=`. $base/../version.sh`
: ${version:=0.0.0-pre0}
: ${pkgversion:=`echo "$version" | sed 's/-/~/g'`}
: ${rpmrevision:=1}
: ${rpmbuild:=$dist}
: ${rpmarch:=`uname -m`}
: ${source:=BUILD/smlsharp-$version.tar.gz}
: ${changelog:=BUILD/smlsharp-$pkgversion-rpm.changelog}
: ${rpmmyth:=BUILD/massivethreads-$mythversion-$rpmbuild.tar}
set -ex
test "_$rpmbuild" = "_$dist" || exit
rpmversion="$pkgversion-$rpmrevision.$rpmbuild"

## reserve stdout for the result
exec 3>&1 1>&2

## install prerequisites
requires=`tar -tf "$host/$rpmmyth"`
requires=`echo "$requires" | grep '\.rpm$' | head -n2`
tar -xf "$host/$rpmmyth" $requires
rpm -i $requires

## set up source tree
mkdir -p /root/rpmbuild/SPECS /root/rpmbuild/SOURCES
cd /root/rpmbuild
cp "$base/smlsharp.spec" SPECS
cp "$host/$source" "SOURCES/smlsharp-$version.tar.gz"

## edit spec files for the build version
sed -i \
    -e '1,/^%changelog/!d' \
    -e "s,0.0.0~pre0,$pkgversion,g;s,0.0.0-pre0,$version,g" \
    SPECS/smlsharp.spec
cat "$host/$changelog" >> SPECS/smlsharp.spec

## substitute LLVM version with the lastest one available in the distribution 
case "$rpmbuild" in
  el7)
    sed -i 's/^BuildRequires: llvm.*/BuildRequires: llvm9.0-devel/' \
      SPECS/smlsharp.spec
    sed -i 's/^Requires: llvm.*/Requires: llvm9.0/' \
      SPECS/smlsharp.spec
    sed -i 's,^%configure,& --with-llvm=%{_libdir}/llvm9.0,' \
      SPECS/smlsharp.spec
    ;;
  el8)
    sed -i '/^BuildRequires: llvm-devel/{s/12/10/;s/13/11/;}' \
      SPECS/smlsharp.spec
    sed -i '/^Requires: llvm/{s/12/10/;s/13/11/;}' \
      SPECS/smlsharp.spec
    ;;
  fc33)
    sed -i '/^BuildRequires: llvm-devel/{s/12/11/;s/13/12/;}' \
      SPECS/smlsharp.spec
    sed -i '/^Requires: llvm/{s/12/11/;s/13/12/;}' \
      SPECS/smlsharp.spec
    ;;
esac

## reset timestamp
tar xzf "SOURCES/smlsharp-$version.tar.gz" "smlsharp-$version/RELEASE"
perl -e '$t=(stat(shift @ARGV))[9];utime $t,$t,@ARGV' \
  "smlsharp-$version/RELEASE" `find SOURCES SPECS`
rm -r "smlsharp-$version"

## for debug
[ -n "$1" ] && exit

## open build log
mkfifo /tmp/buildlog
tee -a "smlsharp-$rpmversion.$rpmarch.build" < /tmp/buildlog &
exec 1>/tmp/buildlog

## build packages
# -v : verbose
# -ba : build source and binary packages
rpmbuild -v -ba SPECS/smlsharp.spec

## check packages
rpmlint -i RPMS/*/*.rpm SRPMS/*.rpm || :

## close build log
exec 1>&-
wait %1

## copy packages to destination
tar -cvf - --transform='s|^.*/||' \
  "RPMS/$rpmarch/smlsharp-$rpmversion.$rpmarch.rpm" \
  "RPMS/$rpmarch/smlsharp-smlformat-$rpmversion.$rpmarch.rpm" \
  "RPMS/$rpmarch/smlsharp-smllex-$rpmversion.$rpmarch.rpm" \
  "RPMS/$rpmarch/smlsharp-smlyacc-$rpmversion.$rpmarch.rpm" \
  "RPMS/$rpmarch/smlsharp"*-debug*"-$rpmversion.$rpmarch.rpm" \
  "SRPMS/smlsharp-$rpmversion.src.rpm" \
  "smlsharp-$rpmversion.$rpmarch.build" \
  1>&3
