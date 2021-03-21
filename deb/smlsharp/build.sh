#!/bin/sh
export TZ=UTC-9
nproc=`grep processor /proc/cpuinfo | wc -l`
base=`dirname $0`
host="$base/../.."
dist=`awk '!/^#/{print $3;exit}' /etc/apt/sources.list`
: ${version:=0.0.0-pre0}
: ${pkgversion:=`echo "$version" | sed 's/-/~/g'`}
: ${debrevision:=1}
: ${debdist=$dist}
: ${debbuild=${debdist:++1~${debdist}1}}
: ${debarch:=`uname -m | sed 's/x86_64/amd64/'`}
: ${source:=BUILD/smlsharp-$version.tar.gz}
: ${changelog:=BUILD/smlsharp_$pkgversion-deb.changelog}
: ${mythversion:=1.00-1}
: ${debmyth:=BUILD/massivethreads-$mythversion-$debarch.tar}
set -ex
test "_$debdist" = "_$dist" || (
  . /etc/lsb-release
  [ "_$DISTRIB_ID" = "_Ubuntu" ] && [ "_$DISTRIB_RELEASE" = "_$debdist" ]
)

debversion="$pkgversion-${debrevision}${debbuild}"

## reserve stdout for the result
exec 3>&1 1>&2

## install prerequisites
requires=`tar -tf "$host/$debmyth"`
requires=`echo "$requires" | grep '\.deb$' | head -n2`
tar -xf "$host/$debmyth" $requires
dpkg -i $requires

## set up source tree
cp -p "$host/$source" "smlsharp_$pkgversion.orig.tar.gz"
tar -xzf "smlsharp_$pkgversion.orig.tar.gz"
cp -r "$base/debian" "smlsharp-$version"
debiandir="smlsharp-$version/debian"
cp "$host/$changelog" "$debiandir/changelog"

## check version
head=`sed -n '/^[^ ]/{;p;q;}' "$debiandir/changelog"`
case "$head" in
"smlsharp (${pkgversion}-${debrevision}) unstable; "*) ;;
*) exit 1;;
esac

## add a new entry to changelog
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
  sed -i -e 's/llvm-11/llvm-7/' "$debiandir/control"
  sed -i -e 's/llvm-11/llvm-7/' "$debiandir/rules"
  ;;
focal)
  echo 12 > "$debiandir/compat"
  sed -i -e 's/debhelper (>=13)/debhelper (>=12)/' "$debiandir/control"
  sed -i -e '/^Standards-Version:/s/4.5.1/4.5.0/' "$debiandir/control"
  sed -i -e 's/llvm-11/llvm-10/' "$debiandir/control"
  sed -i -e 's/llvm-11/llvm-10/' "$debiandir/rules"
  ;;
groovy)
  sed -i -e '/^Standards-Version:/s/4.5.1/4.5.0/' "$debiandir/control"
  ;;
esac

## reset timestamp
perl -e '$t=(stat(shift @ARGV))[9];utime $t,$t,@ARGV' \
  "smlsharp-$version/RELEASE" `find "$debiandir"`

[ -n "$1" ] && exit

## build packages
# (-nc : do not clean before build)
# -uc : do not sign .changes file
# -us : do not sign .dsc file
# -Zxz : use xz to compress debian.tar
# -jN : build with parallel N processes
# -r : do not use fakeroot
# --lintian-opts -i : make lintian more descriptive
(cd "smlsharp-$version" \
 && debuild -uc -us -Zxz -j$nproc -r --lintian-opts -i)

## copy packages to destination
tar cvf - \
  "smlsharp_${debversion}_$debarch.deb" \
  "smlformat_${debversion}_$debarch.deb" \
  "smllex_${debversion}_$debarch.deb" \
  "smlyacc_${debversion}_$debarch.deb" \
  "smlsharp_$debversion.dsc" \
  "smlsharp_$debversion.debian.tar.xz" \
  "smlsharp_$pkgversion.orig.tar.gz" \
  "smlsharp_${debversion}_$debarch.build" \
  "smlsharp_${debversion}_$debarch.changes" \
  1>&3
