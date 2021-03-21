#!/bin/sh
export TZ=UTC-9
base=`dirname $0`
host="$base/../.."
: ${rpmversion:=rawhide-1-0}
rpmos=${rpmversion%%-*}
set -ex

## reserve stdout for the result
exec 3>&1 1>&2

## give a specific name for each operating system
name=smlsharp-release-$rpmos
repo=smlsharp.$rpmos.repo

## setup build directory
mkdir -p /root/rpmbuild/SPECS /root/rpmbuild/SOURCES
cd /root/rpmbuild
cp "$base/smlsharp-release-$rpmversion.spec" "SPECS/$name.spec"
cp "$base/yum.repos.d/$repo" "SOURCES/$repo"
gpg --import-options import-minimal --import "$host/signing-key-pub.asc"
gpg --armor --export > SOURCES/RPM-GPG-KEY-smlsharp

## reset timestamp
date=`sed -n '1,/^%changelog/d;/^\*/{p;q;}' "SPECS/$name.spec"`
date=`echo "$date" | cut -d' ' -f2-5`
date=`date -d "$date" '+%s'`
perl -e '$t=shift @ARGV;utime $t,$t,@ARGV' "$date" \
  "SPECS/$name.spec" "SOURCES/$repo" "SOURCES/RPM-GPG-KEY-smlsharp"

[ -n "$1" ] && exit

## open build log
mkfifo /tmp/buildlog
tee -a "smlsharp-release-$rpmversion.noarch.build" < /tmp/buildlog &
exec 1>/tmp/buildlog

## build packages
# -v : verbose
# -ba : build source and binary packages
rpmbuild -v -ba "SPECS/$name.spec"

## check packages
rpmlint -i RPMS/*/*.rpm SRPMS/*.rpm || :

## close build log
exec 1>&-
wait %1

## copy packages to destination
tar -cvf - --transform 's|^.*/||' \
  "RPMS/noarch/smlsharp-release-$rpmversion.noarch.rpm" \
  "SRPMS/smlsharp-release-$rpmversion.src.rpm" \
  "smlsharp-release-$rpmversion.noarch.build" \
  1>&3
