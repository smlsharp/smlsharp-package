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

#### clone /repos/ to repos/ by symbolic links
find /repos -type d ! -name '.*' \
     -exec sh -e -c 'for a; do mkdir -p "${a#/}"; done' -- '{}' +
find /repos -type f ! -name '.*' \
     -exec sh -e -c 'for a; do ln -s "$a" "${a#/}"; done' -- '{}' +

#### sign all .changes, .buildinfo, and .dsc files
find repos -name '*.changes' | while read i; do
  debsign -p "$gpg" -k "$fpr" --no-re-sign "$i" 9<<-END
	$password
	END
done

#### create Packages and Sources for each distribution
for OS_NAME in $OS_LIST; do
  (
    cd "repos/$OS_NAME"
    apt-ftparchive packages pool > Packages
    apt-ftparchive sources pool > Sources_
  )
done

#### separate Packages for each architecture
for OS_NAME in $OS_LIST; do
  perl -e '
    $/="";
    foreach(<>) {
      /^Architecture: *(.*)$/m;
      open(OUT, ">>${ARGV}_$1") or die "$!";
      print OUT $_;
      close(OUT);
    }
  ' "repos/$OS_NAME/Packages"
  rm "repos/$OS_NAME/Packages"
done

#### separate Packages_* and Sources for each distribution
for OS_NAME in $OS_LIST; do
  for i in repos/"$OS_NAME"/Packages_* repos/"$OS_NAME"/Sources_; do
    [ -r "$i" ] || continue
    perl -e '
      $/="";
      foreach(<>) {
        /^Version: *(.*)$/m;
        $v=$1;
        $v=~s/^.*-[^-~]*~?//;
        $v=~s/[.+]?\d+$//;
        open(OUT, ">>${ARGV}_$v") or die "$!";
        print OUT $_;
        close(OUT);
      }
    ' "$i"
    rm "$i"
  done
done

#### distribute Packages_all_* to Packages_*_*
for OS_NAME in $OS_LIST; do
  for i in repos/"$OS_NAME"/Packages_all_*; do
    [ -r "$i" ] || continue
    OS_CODENAME=${i#repos/$OS_NAME/Packages_all_}
    for packages in repos/"$OS_NAME"/Packages_*_$OS_CODENAME; do
      [ "$i" = "$packages" ] || cat "$i" >> "$packages"
    done
    rm "$i"
  done
done

#### move Packages_* and Sources_* to appropriate directory and compress them
. /scripts/os_codename.sh
for OS_NAME in $OS_LIST; do
  for i in repos/"$OS_NAME"/Packages_* repos/"$OS_NAME"/Sources_*; do
    [ -r "$i" ] || continue
    FILENAME=${i%%_*}
    FILENAME=${FILENAME##*/}
    OS_ARCH=${i#*_}
    OS_ARCH=${OS_ARCH%%_*}
    OS_VERSION=${i#*_*_}
    OS_VERSION=${OS_VERSION#$OS_NAME}
    OS_VERSION=${OS_VERSION:-sid}
    os_codename || OS_CODENAME=$OS_VERSION

    case "$FILENAME" in
      Sources)
        dir="repos/$OS_NAME/dists/$OS_CODENAME/main/source"
        apt-sortpkgs -s "$i" > "$FILENAME"
        ;;
      Packages)
        dir="repos/$OS_NAME/dists/$OS_CODENAME/main/binary-$OS_ARCH"
        apt-sortpkgs "$i" > "$FILENAME"
        ;;
    esac

    if [ -r "$dir/$FILENAME" ] && cmp "$FILENAME" "$dir/$FILENAME"; then
      : "$dir/$FILENAME is unchanged"
    else
      rm -f "$dir/$FILENAME" "$dir/$FILENAME.xz"
      mkdir -p "$dir"
      cp "$FILENAME" "$dir/$FILENAME"
      xz -c "$dir/$FILENAME" > "$dir/$FILENAME.xz"
    fi
    rm "$i" "$FILENAME"
  done
done

#### create InRelease
for OS_NAME in $OS_LIST; do
  for i in repos/"$OS_NAME"/dists/*; do
    [ -d "$i" ] || continue
    OS_CODENAME=${i#repos/$OS_NAME/dists/}

    #### skip distribution that are not updated
    [ $(find "$i/main" -type f | wc -l) -gt 0 ] || continue

    #### get architectures list
    ARCH_LIST=$(cd $i/main && echo binary-* | sed "s|binary-||g")
    [ "$ARCH_LIST" != "*" ] || ARCH_LIST=any

    #### generate InRelease
    cat <<-END > InRelease
	Suite: $OS_CODENAME
	Architectures: $ARCH_LIST
	Components: main
	Origin: smlsharp
	Description: SML# project
	END
    apt-ftparchive release "$i" >> InRelease
    rm -f "$i/InRelease"
    $gpg --clearsign -u "$fpr" -o "$i/InRelease" InRelease 9<<-END
	$password
	END
    rm InRelease
  done
done

#### create supplemental files
for OS_NAME in $OS_LIST; do
  for i in repos/"$OS_NAME"/dists/*; do
    [ -d "$i" ] || continue
    OS_CODENAME=${i#repos/$OS_NAME/dists/}

    #### create smlsharp-archive-keyring.gpg
    if [ ! -r "$i/smlsharp-archive-keyring.gpg" ]; then
      $gpg1 --export "$fpr" > "$i/smlsharp-archive-keyring.gpg"
    fi

    #### create smlsharp.sources
    if [ ! -r "$i/smlsharp.sources" ] && [ ! -r "$i/smlsharp.list" ]; then
      TYPES=
      if ls "$i"/main/binary-*/Packages > /dev/null 2>&1; then
        TYPES="$TYPES deb"
      fi
      if [ -r "$i/main/source/Sources" ]; then
        TYPES="$TYPES deb-src"
      fi
      cat <<-END >> "$i/smlsharp.sources"
	Types:$TYPES
	URIs: https://smlsharp.github.io/repos/$OS_NAME
	Suites: $OS_CODENAME
	Components: main
	Signed-By: /etc/apt/keyrings/smlsharp-archive-keyring.gpg
	END
    fi
  done
done

#### output the result
find repos -type f | tar -T - -cf /build/deb_build_repository.tar
