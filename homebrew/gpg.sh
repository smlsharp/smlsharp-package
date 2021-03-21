#!/bin/sh

exec 6<&0 7>&1 8>&2 2>/dev/tty 1>&2 0<&-
set -e
umask 077
onexit=
trap 'set +e; eval "$onexit"' EXIT

## create temporary GNUPGHOME
export GNUPGHOME=`mktemp -d`
onexit="rmdir \"\$GNUPGHOME\"; $onexit"

## mount RAM disk on GNUPGHOME
dev=`hdiutil attach -nomount ram://32768`
dev=`echo $dev`
onexit="hdiutil detach \"\$dev\"; $onexit"
newfs_hfs -M 700 -s "$dev" >/dev/null 1>&2
mount -t hfs "$dev" "$GNUPGHOME"

## import the secret key given from fd 9
onexit="gpgconf --kill gpg-agent </dev/null; $onexit"
read pass 0<&9
gpg --quiet --with-colon --batch --import 0<&9
exec 9<&-

## obtain the fingerprint
fpr=`gpg --quiet --with-colon --batch --list-keys --with-fingerprint \
     | sed '/^fpr/!d' | cut -d: -f10`
test -n "$fpr"

## replace signingKey with the fingerprint
i=1
args=
for a; do
  if [ "x$a" = "x@SIGNINGKEY@" ]
  then args="$args \"\$fpr\""
  else args="$args \"\$$i\""
  fi
  i=$(($i+1))
done

## sign the commit
eval gpg --with-colon --batch --passphrase-fd 9 --pinentry-mode loopback \
     $args 0<&6 1>&7 2>&8 9<<-END
	$pass
	END
