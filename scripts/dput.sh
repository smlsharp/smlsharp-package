#!/bin/sh
BASE=$(dirname "$0")/..
: ${PODMAN:=podman}
set -ex

[ -n "$1" ] || exit 1
SRCDIR=$(cd -- $(dirname "$1") && pwd -P)
CHANGES=$(basename "$1")

(
  cd "$BASE/dockerfiles/ubuntu-dput"
  $PODMAN build -t ubuntu-dput .
)

gpg --batch --decrypt "$BASE/keys/ppa-key_$(whoami).asc" \
| $PODMAN run --rm -i --sig-proxy=false \
          -v "$SRCDIR:/src:ro" \
          --tmpfs /root/.gnupg:size=1m,mode=700 \
          -w /root \
          -e "CHANGES=$CHANGES" \
          ubuntu-dput \
          sh -exc '
  #### read the GPG secret key and its password from stdin
  unset password
  read password
  gpg1="gpg --pinentry-mode loopback --batch --with-colon"
  $gpg1 --import --always-trust
  exec 0<&- 0</dev/null

  #### get fingerprint of the GPG key
  fpr=$($gpg1 --list-keys --with-fingerprint | sed "/^fpr/!d" | cut -d: -f10)
  gpg="$gpg1 --passphrase-fd 9 --digest-algo SHA256 --no-emit-version"

  #### trust the imported GPG key ultimately
  $gpg1 --import-ownertrust <<-END
	$fpr:6:
	END

  #### clone /src to /root by symbolic links
  find /src -type f ! -name ".*" \
       -exec sh -e -c '\''for a; do ln -s "$a" "${a#/src/}"; done'\'' -- "{}" +

  #### resign the source package
  debsign -p "$gpg" -k "$fpr" --re-sign "$CHANGES" 9<<-END
	$password
	END

  #### upload the source package to PPA
  dput ppa:smlsharp/ppa "$CHANGES"
'
