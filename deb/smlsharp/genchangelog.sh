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
  tz=`echo "$tz" | sed 's/JST/+0900/'`
  version=`echo "$ver" | sed y/-/~/`
  if expr "$version" : '[A-Za-z0-9][.+~A-Za-z0-9]*$' > /dev/null; then
    :
  else
    echo "*** MALFORMED VERSION NUMBER $version" 1>&2
    exit 1
  fi
  d=`perl -mTime::Piece -e 'print Time::Piece->strptime(shift(@ARGV),"%Y-%m-%d %H:%M:%S")->strftime("%a, %d %b %Y %H:%M:%S")' "$date $time"`
  who_is_maintainer
  echo "smlsharp ($version-1) unstable; urgency=low"
  echo
  if test "x$version" = "x$first_version"; then
    echo "  * Initial Release."
  else
    echo "  * New upstream release."
  fi
  echo
  echo " -- $maintainer  $d $tz"
  echo
  test "x$version" != "x$first_version" || break
done
