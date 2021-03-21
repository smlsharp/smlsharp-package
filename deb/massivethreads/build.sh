#!/bin/sh
export TZ=UTC-9
nproc=`grep processor /proc/cpuinfo | wc -l`
base=`dirname $0`
host="$base/../.."
dist=`awk '!/^#/{print $3;exit}' /etc/apt/sources.list`
: ${version:=1.00}
: ${pkgversion:=`echo "$version" | sed 's/-/~/g'`}
: ${debrevision:=1}
: ${debdist=$dist}
: ${debbuild=${debdist:++1~${debdist}1}}
: ${debarch:=`uname -m | sed 's/x86_64/amd64/'`}
: ${source:=BUILD/massivethreads-$version.tar.gz}
set -ex
test "_$debdist" = "_$dist" || (
  . /etc/lsb-release
  [ "_$DISTRIB_ID" = "_Ubuntu" ] && [ "_$DISTRIB_RELEASE" = "_$debdist" ]
)
debversion="$pkgversion-${debrevision}${debbuild}"

## reserve stdout for the result
exec 3>&1 1>&2

## obtain the directory name of the source package
srcdir=`tar -tf "$host/$source" | head -n1`
case "$srcdir" in
  massivethreads-*/) srcdir=${srcdir%/} ;;
  *) exit 1
esac

## set up source tree
cp -p "$host/$source" "massivethreads_$pkgversion.orig.tar.gz"
tar -xzf "massivethreads_$pkgversion.orig.tar.gz"
cp -r "$base/debian" "$srcdir"
cp "$host"/massivethreads/man/* "$srcdir/debian"
debiandir="$srcdir/debian"

## check version
head=`sed -n '/^[^ ]/{;p;q;}' "$debiandir/changelog"`
case "$head" in
"massivethreads (${pkgversion}-${debrevision}) unstable; "*) ;;
*) exit 1;;
esac

## add a new entry to changelog if distributions is other than sid
if [ -n "$debbuild" ]; then
  sed -i -e "1i\\
`echo "$head" | sed "s/(\\(.*\\)) unstable/(\\1${debbuild}) $dist/"`\\
\\
  * Build for $dist.\\
\\
`sed -n '/^ -- /{;s/  .*$//;p;q;}' "$debiandir/changelog"`  `date -R`\\
" "$debiandir/changelog"
fi

## downgrade the compat level for old systems
case "$dist" in
buster)
  echo 12 > "$debiandir/compat"
  sed -i -e 's/debhelper (>=13)/debhelper (>=12)/' "$debiandir/control"
  sed -i -e '/^Standards-Version:/s/4.5.1/4.3.0/' "$debiandir/control"
  ;;
focal)
  echo 12 > "$debiandir/compat"
  sed -i -e 's/debhelper (>=13)/debhelper (>=12)/' "$debiandir/control"
  sed -i -e '/^Standards-Version:/s/4.5.1/4.5.0/' "$debiandir/control"
  ;;
groovy)
  sed -i -e '/^Standards-Version:/s/4.5.1/4.5.0/' "$debiandir/control"
  ;;
esac

## reset timestamp
perl -e '$t=(stat(shift @ARGV))[9];utime $t,$t,@ARGV' \
  "$srcdir/COPYRIGHT" `find "$debiandir"`

[ -n "$1" ] && exit

## build packages
# (-nc : do not clean before build)
# -uc : do not sign .changes file
# -us : do not sign .dsc file
# -Zxz : use xz to compress debian.tar
# -jN : build with parallel N processes
# -r : do not use fakeroot
# --lintian-opts -i : make lintian more descriptive
(cd "$srcdir" \
 && debuild -uc -us -Zxz -j$nproc -r --lintian-opts -i)

## copy packages to destination
tar cf - \
  "massivethreads_${debversion}_$debarch.deb" \
  "massivethreads-dev_${debversion}_$debarch.deb" \
  "massivethreads-ld_${debversion}_$debarch.deb" \
  "massivethreads-ld-dev_${debversion}_$debarch.deb" \
  "massivethreads-dl_${debversion}_$debarch.deb" \
  "massivethreads-dr_${debversion}_$debarch.deb" \
  "massivethreads-dr-dev_${debversion}_$debarch.deb" \
  "massivethreads-doc_${debversion}_all.deb" \
  "massivethreads_$debversion.dsc" \
  "massivethreads_$debversion.debian.tar.xz" \
  "massivethreads_$pkgversion.orig.tar.gz" \
  "massivethreads_${debversion}_$debarch.build" \
  "massivethreads_${debversion}_$debarch.changes" \
  1>&3
