#!/bin/sh
export TZ=UTC-9
base=`dirname $0`
host="$base/.."
LF='
'
set -ex

## reserve stdout for the result
exec 3>&1 1>&2

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
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/o"
mkdir "$tmp/x"

## extract given archives
for archive; do
  mkdir "$tmp/t"
  tar -xf "$host/$archive" -C "$tmp/t"
  for i in "$tmp"/t/*; do
    j="$tmp/x/${i##*/}"
    if cmp "$i" "$j" > /dev/null 2>&1; then
      :
    elif [ -s "$j" ]; then
      exit 1
    else
      mv "$i" "$j"
    fi
  done
  rm -rf "$tmp/t"
done

## generate .changes file for each .dsc file
for dsc in "$tmp"/x/*.dsc; do
  test "_$dsc" = "_$tmp/x/*.dsc" && break
  dsc=${dsc##*/}
  name=${dsc%.dsc}
  dpkg-source -x "$tmp/x/$dsc" "$tmp/o/.src"
  cp -p "$tmp/x/$name.debian.tar.xz" "$tmp/o"
  cp -p "$tmp/x/$dsc" "$tmp/o"
  (cd "$tmp/o/.src" && dpkg-genchanges -sa --build=source) > "$tmp/o/${name}_source.changes"
  rm -rf "$tmp/o/.src"
done

## sign .dsc and .changes files
for changes in "$tmp"/o/*.changes; do
  test "_$changes" = "_$tmp/o/*.changes" && break
  debsign -p "$gpg" -k "$id" --re-sign "$changes" 9<<-END
	$pass
	END
done

## archive all generated files
(cd "$tmp" && find o -type f -print | sed 's,^o/,,') > "$tmp/files"
tar -C "$tmp/o" -cf "$tmp/out.tar" -T "$tmp/files"

## output the result
cat "$tmp/out.tar" 1>&3
