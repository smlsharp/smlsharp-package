#!/bin/sh
export TZ=UTC-9
base=`dirname $0`
host="$base/.."
: ${rootbasedir:=DOWNLOAD}
: ${roots:=debian ubuntu}
LF='
'
set -ex

## reserve stdout for the result
exec 3>&1 1>&2

## if the argument starts with "--debug", we are in debugging mode.
debug=
if [ "_$1" = "_--debug" ]; then
  debug=yes
  shift 1
fi

## read the signing secret key and its password from stdin
unset pass
read pass
gpg='gpg --homedir=/mnt/ram --pinentry-mode loopback --batch --with-colon'
$gpg --import
exec 0<&- 0</dev/null
id=`$gpg --list-keys --with-fingerprint | sed -n '/^fpr/{;p;q;}' | cut -d: -f10`
gpg="$gpg --passphrase-fd 9 --default-key $id"
gpg="$gpg --digest-algo SHA256 --no-emit-version"

## create temporary directory
tmp=`mktemp -d`
if [ -n "$debug" ]; then
  trap 'echo "$tmp"' EXIT
else
  trap 'rm -rf "$tmp"' EXIT
fi

## clone rootbasedir to $tmp/r by symbolic-linking
for root in $roots; do
  (
    dir="$host/$rootbasedir"
    cd "$dir"
    export tmp dir
    test -d "$root" || exit 0
    find "$root" -type d \
      -exec sh -exc 'for a; do mkdir -p "$tmp/r/$a"; done' -- '{}' +
    find "$root" -type f \
      -exec sh -exc 'for a; do ln -s "$dir/$a" "$tmp/r/$a"; done' -- '{}' +
  )
done

## extract given archives to the given place
while [ "$#" -ge 3 ]; do
  # $1=tar, $2=<os>/<ver>, $3=destdir
  mkdir -p "$tmp/p/$2/$3"
  tar -xf "$host/$1" -C "$tmp/p/$2/$3"
  shift 3
done

## merge $tmp/p/<os>/<var>/... to $tmp/r/...
for i in "$tmp"/p/*/*; do
  test "_$tmp/p/*/*" = "_$i" && break
  files=`cd "$i" && find . -type f -print`
  for file in $files; do
    if cmp "$tmp/r/$file" "$i/$file" > /dev/null 2>&1; then
      :
    elif [ -s "$tmp/r/$file" ]; then
      exit 1
    else
      case "$file" in
        *.deb|*.dsc|*.debian.tar.xz|*.orig.tar.gz|*.gpg|*.list)
	  mkdir -p "$tmp/r/${file%/*}"
          mv "$i/$file" "$tmp/r/$file"
          ln -s "$tmp/r/$file" "$i/$file"
          ;;
      esac
    fi
  done
done

## sign .dsc files in $tmp/r
files=`find "$tmp/r" -type f -name '*.dsc' -print`
while IFS="$LF" read file; do
  debsign -p "$gpg" -k "$id" --no-re-sign "$file" 9<<-END
	$pass
	END
done <<-END
	$files
	END

## create Packages and Sources for each distribution
## there must be a package pool at $tmp/p/<os>/<ver>/<os>/pool.
for i in "$tmp"/p/*/*/*/pool; do
  test "_$tmp/p/*/*/*/pool" = "_$i" && break
  i=${i%/pool}
  j=${i%/*}
  (cd "$i" && apt-ftparchive packages pool) > "$j/Packages"
  (cd "$i" && apt-ftparchive sources pool) > "$j/Sources"
done

## separate Packages for each architecture
for i in "$tmp"/p/*/*/Packages; do
  test "_$tmp/p/*/*/Packages" = "_$i" && break
  i=${i%/Packages}
  awk -v RS='' '
    {$0=$0"\n"}
    {a=$0; sub("^.*\nArchitecture: *","",a); sub("\n.*$","",a)}
    {print > FILENAME"_"a}
  ' "$i/Packages"
done

## append all-architecture Packages to each architecture's Packages
for i in "$tmp"/p/*/*/Packages_all; do
  test "_$tmp/p/*/*/Packages_all" = "_$i" && break
  for j in ${i%_all}_*; do
    test "_${i%_all}_*" = "_$j" && break
    [ "$j" = "$i" ] || cat "$i" >> "$j"
  done
  rm "$i"
done

## make $tmp/r/<os>/dists/<ver>/main/binary-<arch>/Packages{,xz}
## from $tmp/p/<os>/<ver>/Packages_<arch>
for i in "$tmp"/p/*/*/Packages_*; do
  test "_$tmp/p/*/*/Packages_*" = "_$i" && break
  os=${i#"$tmp"/p/}
  os=${os%%/*}
  ver=${i#"$tmp"/p/"$os"/}
  ver=${ver%%/*}
  arch=${i#"$tmp"/p/"$os"/"$ver"/Packages_}
  dir="$tmp/r/$os/dists/$ver/main/binary-$arch"
  mkdir -p "$dir"
  [ -s "$dir/Packages" ] && cat "$dir/Packages" >> "$i"
  rm -f "$dir/Packages" "$dir/Packages.xz"
  apt-sortpkgs "$i" > "$dir/Packages"
  xz -ek "$dir/Packages"
done

## make $tmp/r/<os>/dists/<ver>/main/source/Sources{,xz}
## from $tmp/p/<os>/<ver>/Sources
for i in "$tmp"/p/*/*/Sources; do
  test "_$tmp/p/*/*/Sources" = "_$i" && break
  os=${i#"$tmp"/p/}
  os=${os%%/*}
  ver=${i#"$tmp"/p/"$os"/}
  ver=${ver%%/*}
  dir="$tmp/r/$os/dists/$ver/main/source"
  mkdir -p "$dir"
  [ -s "$dir/Sources" ] && cat "$dir/Sources" >> "$i"
  rm -f "$dir/Sources" "$dir/Sources.xz"
  apt-sortpkgs "$i" > "$dir/Sources"
  xz -ek "$dir/Sources"
done

## make $tmp/r/<os>/<ver>/InRelease
for i in "$tmp"/p/*/*; do
  test "_$tmp/p/*/*" = "_$i" && break
  os=${i#"$tmp"/p/}
  os=${os%%/*}
  ver=${i#"$tmp"/p/"$os"/}
  ver=${ver%%/*}
  archs=`cd "$i" && echo Packages_* | sed 's/Packages_//g'`
  test "_$archs" = "_*" && break
  echo "Suite: $ver" > "$i/InRelease"
  echo "Architectures: $archs" >> "$i/InRelease"
  echo 'Components: main' >> "$i/InRelease"
  echo 'Origin: smlsharp' >> "$i/InRelease"
  echo 'Description: SML# project' >> "$i/InRelease"
  apt-ftparchive release "$tmp/r/$os/dists/$ver" >> "$i/InRelease"
done

## sign InRelease and create $tmp/r/<os>/dists/<ver>/InRelease
for i in "$tmp"/p/*/*/InRelease; do
  test "_$tmp/p/*/*/InRelease" = "_$i" && break
  os=${i#"$tmp"/p/}
  os=${os%%/*}
  ver=${i#"$tmp"/p/"$os"/}
  ver=${ver%%/*}
  rm -f "$tmp/r/$os/dists/$ver/InRelease"
  $gpg --clearsign --output "$tmp/r/$os/dists/$ver/InRelease" "$i" 9<<-END
	$pass
	END
done

## archive all modified files
files=`cd "$tmp/r" && find * -type f -print`
tar -cf "$tmp/out.tar" -C "$tmp/r" -T- --owner=root:0 --group=root:0 <<-END
	$files
	END

## output the result
[ -n "$debug" ] && exit
cat "$tmp/out.tar" 1>&3
