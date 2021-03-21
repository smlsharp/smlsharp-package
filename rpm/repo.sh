#!/bin/sh
export TZ=UTC-9
base=`dirname $0`
host="$base/.."
: ${rootbasedir:=DOWNLOAD}
: ${roots:=fedora centos}
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
gpg="$gpg --default-key $id --digest-algo SHA256 --no-emit-version"

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
    [ -d "$root" ] || exit 0
    find "$root" -type d \
      -exec sh -exc 'for a; do mkdir -p "$tmp/r/$a"; done' -- '{}' +
    find "$root" -type f \
      -exec sh -exc 'for a; do ln -s "$dir/$a" "$tmp/r/$a"; done' -- '{}' +
  )
done

## extract given archives to the given place
while [ "$#" -ge 3 ]; do
  # $1=tar, $2=binpackdir, $3=srcpackdir
  mkdir -p "$tmp/r/$2"
  mkdir -p "$tmp/r/$3"
  tar -xvf "$host/$1" -C "$tmp/r/$2" --skip-old-files \
    --exclude='*.src.rpm' --exclude='*-debug*' --wildcards '*.rpm'
  tar -xvf "$host/$1" -C "$tmp/r/$3" --skip-old-files \
    --wildcards '*.src.rpm'
  shift 3
done

## import public key to rpm
$gpg --export --armor > "$tmp/pubkey"
rpm --import "$tmp/pubkey"

## sign .rpm files
files=`find "$tmp/r" -type f -name '*.rpm' -print`
while IFS="$LF" read file; do
  GPG_TTY=/dev/null \
  rpmsign --addsign \
    --define '%_gpg_path /mnt/ram' \
    --define "%_gpg_name $id" \
    --define \
    '%_gpg_sign_cmd_extra_args --pinentry-mode loopback --passphrase-fd 9' \
    "$file" 9<<-END
	$pass
	END
done <<-END
	$files
	END

## make $tmp/r/<os>/<ver>/<arch>/repodata
## from $tmp/r/<os>/<ver>/<arch>/Packages
for i in "$tmp"/r/*/*/*/Packages/; do
  test "_$tmp/r/*/*/*/Packages/" = "_$i" && break
  files=`find "$i" -type f | head -n1`
  [ -n "$files" ] || continue
  i=${i%/Packages/}
  oldfiles=`[ -d "$i/repodata" ] && find "$i/repodata" ! -type d -print || :`
  createrepo -v "$i"
  rm -f "$i/repodata/repomd.xml.asc"
  $gpg --passphrase-fd 9 --armor --detach-sign \
       --output "$i/repodata/repomd.xml.asc" "$i/repodata/repomd.xml" 9<<-END
	$pass
	END
  for i in $oldfiles; do touch "$i"; done
done

## archive all modified files
files=`cd "$tmp/r" && find * -type f -print`
tar -cf "$tmp/out.tar" -C "$tmp/r" -T- <<-END
	$files
	END

## output the result
[ -n "$debug" ] && exit
cat "$tmp/out.tar" 1>&3
