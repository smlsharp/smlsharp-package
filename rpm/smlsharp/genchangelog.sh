#!/bin/sh

who_is_maintainer () {
  # Until now, all deb packages are built by Katsuhiro Ueno.
  case "$version" in
    *)
      maintainer='Katsuhiro Ueno <katsu@riec.tohoku.ac.jp>'
      ;;
  esac
}

export LANG=C
first_version=3.0.0

set -e

sed 's/[()]//g' | while IFS=' ' read ver date time tz; do
  version=`echo "$ver" | sed y/-/~/`
  if expr "$version" : '[A-Za-z0-9][.+~A-Za-z0-9]*$' > /dev/null; then
    :
  else
    echo "*** MALFORMED VERSION NUMBER $version" 1>&2
    exit 1
  fi
  d=`perl -mTime::Piece -e 'print Time::Piece->strptime(shift(@ARGV),"%Y-%m-%d %H:%M:%S")->strftime("%a %b %e %Y")' "$date $time"`
  who_is_maintainer
  echo "* $d $maintainer - $version-1"
  if test "x$version" = "x$first_version"; then
    echo "- Initial package."
    break
  else
    echo "- New upstream release."
    echo
  fi
done
