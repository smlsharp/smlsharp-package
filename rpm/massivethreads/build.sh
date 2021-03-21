#!/bin/sh
export TZ=UTC-9
base=`dirname $0`
host="$base/../.."
dist=`. $base/../version.sh`
: ${version:=1.00}
: ${pkgversion:=`echo "$version" | sed 's/-/~/g'`}
: ${rpmrevision:=1}
: ${rpmbuild:=$dist}
: ${rpmarch:=`uname -m`}
: ${source:=BUILD/massivethreads-$version.tar.gz}
: ${man:=$host/BUILD/massivethreads-$version-manpages.patch}
set -ex
test "_$rpmbuild" = "_$dist" || exit
rpmversion="$pkgversion-$rpmrevision.$rpmbuild"

## reserve stdout for the result
exec 3>&1 1>&2

## obtain the directory name of the source package
srcdir=`tar -tf "$host/$source" | head -n1`
case "$srcdir" in
  massivethreads-*/) srcdir=${srcdir%/} ;;
  *) exit 1
esac

## set up source tree
mkdir -p /root/rpmbuild/SPECS /root/rpmbuild/SOURCES
cd /root/rpmbuild
cp "$base/massivethreads.spec" SPECS
cp "$host/$source" "SOURCES/massivethreads-$version.tar.gz"
cp "$host/$man" "SOURCES/massivethreads-$version-manpages.patch"

## version check
case `sed -n '/^Version:/p' SPECS/massivethreads.spec` in
"Version: $pkgversion") ;;
*) exit 1 ;;
esac
case `sed -n '/^Release:/p' SPECS/massivethreads.spec` in
"Release: ${rpmrevision}%{?dist}") ;;
*) exit 1 ;;
esac

## special care for CentOS 7
case "$rpmbuild" in
  el7)
    sed -i '/^%configure/s/$/ CC="gcc -std=gnu99"/' SPECS/massivethreads.spec
    ;;
esac

[ -n "$1" ] && exit

## open build log
mkfifo /tmp/buildlog
tee -a "massivethreads-$rpmversion.$rpmarch.build" < /tmp/buildlog &
exec 1>/tmp/buildlog

## build packages
# -v : verbose
# -ba : build source and binary packages
rpmbuild -v -ba SPECS/massivethreads.spec

## check packages
rpmlint -i RPMS/*/*.rpm SRPMS/*.rpm || :

## close build log
exec 1>&-
wait %1

## copy packages to destination
tar -cvf - --transform='s|^.*/||' \
  "RPMS/$rpmarch/massivethreads-$rpmversion.$rpmarch.rpm" \
  "RPMS/$rpmarch/massivethreads-devel-$rpmversion.$rpmarch.rpm" \
  "RPMS/$rpmarch/massivethreads-ld-$rpmversion.$rpmarch.rpm" \
  "RPMS/$rpmarch/massivethreads-ld-devel-$rpmversion.$rpmarch.rpm" \
  "RPMS/$rpmarch/massivethreads-dl-$rpmversion.$rpmarch.rpm" \
  "RPMS/$rpmarch/massivethreads-dr-$rpmversion.$rpmarch.rpm" \
  "RPMS/$rpmarch/massivethreads-dr-devel-$rpmversion.$rpmarch.rpm" \
  "RPMS/$rpmarch/massivethreads"*-debug*"-$rpmversion.$rpmarch.rpm" \
  "RPMS/noarch/massivethreads-doc-$rpmversion.noarch.rpm" \
  "SRPMS/massivethreads-$rpmversion.src.rpm" \
  "massivethreads-$rpmversion.$rpmarch.build" \
  1>&3
