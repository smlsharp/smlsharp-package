#!/bin/sh
set -ex

#### the following must be given
test -n "$OS_LIST"

#### read the GPG secret key and its password from stdin
unset password
read password
gpg1='gpg --pinentry-mode loopback --batch --with-colon'
$gpg1 --import
exec 0<&- 0</dev/null

#### get fingerprint of the GPG key
fpr=$($gpg1 --list-keys --with-fingerprint | sed '/^fpr/!d' | cut -d: -f10)
gpg="$gpg1 --passphrase-fd 9 --digest-algo SHA256 --no-emit-version"

#### import public key to rpm
$gpg1 --export --armor > pubkey.asc
rpm --import pubkey.asc

#### clone /repos/ to repos/ by symbolic links
find /repos -type d ! -name '.*' \
     -exec sh -e -c 'for a; do mkdir -p "${a#/}"; done' -- '{}' +
find /repos -type f ! -name '.*' \
     -exec sh -e -c 'for a; do ln -s "$a" "${a#/}"; done' -- '{}' +

#### sign .rpm files
find repos -name '*.rpm' | while read i; do
  check=$(rpm -K "$i" || :)
  case "$check" in
    *signatures\ OK) continue ;;
  esac
  orig=$(readlink "$i")
  rm "$i"
  cp "$orig" "$i"
  GPG_TTY=/dev/null \
  rpmsign --addsign \
    --define "%_gpg_name $fpr" \
    --define \
    '%_gpg_sign_cmd_extra_args --pinentry-mode loopback --passphrase-fd 9' \
    "$i" 9<<-END
	$password
	END
done

#### create repodata from Packages
for OS_NAME in $OS_LIST; do
  for i in repos/"$OS_NAME"/*/*/Packages; do
    i=${i%/Packages}
    [ -d "$i/Packages" ] || continue

    #### skip if not updated
    [ $(find "$i/Packages" -type f | wc -l) -gt 0 ] || continue

    #### create repo
    rm -rf "$i/repodata"
    createrepo -v --general-compress-type=gz "$i"
    $gpg --armor --detach-sign --output "$i/repodata/repomd.xml.asc" \
         "$i/repodata/repomd.xml" 9<<-END
	$password
	END
  done
done

#### output the result
find repos -type f | tar -T - -cf /build/rpm_build_repository.tar
