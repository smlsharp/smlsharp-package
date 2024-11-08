#!/bin/sh
BASE=$(dirname "$0")/..
set -ex

#### the following must be given
test -n "$RELEASE_OWNER"
test -n "$RELEASE_TAG"
test -n "$RELEASE_FILENAME"
test -n "$RELEASE_VERSION"
test -n "$RELEASE_DATE"
test -n "$RELEASE_SHA256"

#### derive the following from the given information
RELEASE_URL="https://github.com/$RELEASE_OWNER/smlsharp/releases/download/$RELEASE_TAG/$RELEASE_FILENAME"
TILDE_VERSION=$(echo "$RELEASE_VERSION" | sed 'y/-/~/')

#### save the release infomation
{
  echo "SMLSHARP_URL='$RELEASE_URL'"
  echo "SMLSHARP_VERSION='$RELEASE_VERSION'"
  echo "SMLSHARP_PKGVERSION='$TILDE_VERSION'"
  echo "SMLSHARP_DATE='$RELEASE_DATE'"
  echo "SMLSHARP_SHA256='$RELEASE_SHA256'"
} > "$BASE/scripts/smlsharp/release.sh"

#### update deb package
DEB_DATE=$( \
  LANG=C perl -mTime::Piece -e '
    @a = split(/ /, $ARGV[0], 3);
    $t = Time::Piece->strptime("$a[0] $a[1]", "%Y-%m-%d %H:%M:%S");
    print $t->strftime("%a, %d %b %Y %H:%M:%S ") . $a[2];
  ' "$RELEASE_DATE" \
)
sed -e '/^+smlsharp /s|(.*)|('"$TILDE_VERSION-0v1"')|' \
    -e '/^+ -- /s|  .*$|  '"$DEB_DATE"'|' \
    -i.orig "$BASE/scripts/smlsharp/deb/debian-changelog.diff"
rm "$BASE/scripts/smlsharp/deb/debian-changelog.diff.orig"

#### update rpm package
RPM_DATE=$( \
  LANG=C perl -mTime::Piece -e '
    @a = split(/ /, $ARGV[0], 3);
    $t = Time::Piece->strptime("$a[0] $a[1]", "%Y-%m-%d %H:%M:%S");
    print $t->strftime("%a %b %e %Y");
  ' "$RELEASE_DATE" \
)
RPM_MAINTAINER=$( \
  sed -E \
      -e '1,/^%changelog$/d' \
      -e 's/^\* +[^ ]+ +[^ ]+ +[^ ]+ +[^ ]+ +//;s/ - .*$//' \
      -e 'q' \
      "$BASE/scripts/smlsharp/rpm/smlsharp.spec" \
)
sed -e '/^Source0: /s|.*|Source0: '"$RELEASE_URL"'|' \
    -e '/^Version: /s|.*|Version: '"$TILDE_VERSION"'|' \
    -e '/^Release: /s|.*|Release: 1%{?dist}|' \
    -e '/^%setup /s|%{name}-.*$|%{name}-'"$RELEASE_VERSION"'|' \
    -e '/^%changelog$/a\
* '"$RPM_DATE $RPM_MAINTAINER - $TILDE_VERSION-1"'\
- New upstream release.\
' \
    -i.orig "$BASE/scripts/smlsharp/rpm/smlsharp.spec"
rm "$BASE/scripts/smlsharp/rpm/smlsharp.spec.orig"

#### update Homebrew formula
sed -e '/^  url /s|".*"|"'"$RELEASE_URL"'"|' \
    -e '/^  sha256 /s|".*"|"'"$RELEASE_SHA256"'"|' \
    -e '/^  version /s|".*"|'"$RELEASE_VERSION"'"|' \
    -e '/^  revision /d' \
    -e '/^  bottle do/,/^ *$/d' \
    -i.orig "$BASE/homebrew-smlsharp/Formula/smlsharp.rb"
