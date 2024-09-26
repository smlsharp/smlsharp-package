#!/bin/sh
BASE=$(dirname "$0")/../../..
set -ex

#### the following must be given
test -n "$BUILD"
test -n "$MVTH_BOTTLE_SUFFIX"
test -n "$OS_NAME"
test -n "$OS_VERSION"
test -n "$OS_ARCH"

#### setup Homebrew
. "$BASE/scripts/homebrew_setup.sh"

#### create temporary directory
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 127' INT QUIT STOP

#### build the bottle
$BREW install -v --build-bottle smlsharp/smlsharp/massivethreads
(
  cd "$tmp"
  $BREW bottle -v --json --no-rebuild \
        --root-url https://smlsharp.github.io/repos/homebrew \
        smlsharp/smlsharp/massivethreads
)

#### update and commit the formula
cat "$tmp/massivethreads--${MVTH_BOTTLE_SUFFIX%.tar.gz}.json"
$BREW bottle -v --merge --write \
             "$tmp/massivethreads--${MVTH_BOTTLE_SUFFIX%.tar.gz}.json"

#### rename '--' to '-'
mv "$tmp/massivethreads--$MVTH_BOTTLE_SUFFIX" \
   "$tmp/massivethreads-$MVTH_BOTTLE_SUFFIX"

#### output the result
tar -C "$tmp" \
    -cf "$BUILD/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
    "massivethreads-$MVTH_BOTTLE_SUFFIX"

#### uninstall massivethreads
$BREW uninstall massivethreads
