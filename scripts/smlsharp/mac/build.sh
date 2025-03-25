#!/bin/sh
BASE=$(dirname "$0")/../../..
set -ex

#### the following must be given
test -n "$BUILD"
test -n "$MVTH_BOTTLE_SUFFIX"
test -n "$SMLSHARP_BOTTLE_SUFFIX"
test -n "$OS_NAME"
test -n "$OS_VERSION"
test -n "$OS_ARCH"

#### setup Homebrew
. "$BASE/scripts/homebrew_setup.sh"

#### create temporary directory
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 127' INT QUIT STOP

#### install massivethreads
export HOMEBREW_CACHE="$tmp/cache"
MVTH_BOTTLE="massivethreads-$MVTH_BOTTLE_SUFFIX"
tar -C "$tmp" \
    -xf "$BUILD/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
    "$MVTH_BOTTLE"
homebrew_add_cache \
  "$tmp/$MVTH_BOTTLE" \
  "https://smlsharp.github.io/repos/homebrew/$MVTH_BOTTLE" \
  "massivethreads--$MVTH_BOTTLE_SUFFIX"
$BREW install massivethreads
unset HOMEBREW_CACHE

#### manipulate formula to build a bottle in the standard cellar
(cd "$FORMULADIR" && patch -p0) \
  < "$BASE/scripts/smlsharp/mac/smlsharp.rb.$OS_ARCH.diff"

#### build smlsharp
$BREW install -v --only-dependencies smlsharp/smlsharp/smlsharp
$BREW install -v --build-bottle smlsharp/smlsharp/smlsharp

#### revert the formula to the original
(cd "$FORMULADIR" && patch -p0 -R) \
  < "$BASE/scripts/smlsharp/mac/smlsharp.rb.$OS_ARCH.diff"
(cd "$HOMEBREW_PREFIX/opt/smlsharp/.brew" && patch -p0 -R) \
  < "$BASE/scripts/smlsharp/mac/smlsharp.rb.$OS_ARCH.diff"

#### create the bottle
(
  cd "$tmp"
  $BREW bottle -v --json --no-rebuild \
        --root-url https://smlsharp.github.io/repos/homebrew \
        smlsharp/smlsharp/smlsharp
)

#### remove "cellar" from json
sed -i.orig -e '/^ *"cellar":/d' \
    "$tmp/smlsharp--${SMLSHARP_BOTTLE_SUFFIX%.tar.gz}.json"

#### update and commit the formula
cat "$tmp/smlsharp--${SMLSHARP_BOTTLE_SUFFIX%.tar.gz}.json"
$BREW bottle -v --merge --write \
             "$tmp/smlsharp--${SMLSHARP_BOTTLE_SUFFIX%.tar.gz}.json"

#### rename '--' to '-'
mv "$tmp/smlsharp--$SMLSHARP_BOTTLE_SUFFIX" \
   "$tmp/smlsharp-$SMLSHARP_BOTTLE_SUFFIX"

#### output the result
tar -C "$tmp" \
    -cf "$BUILD/smlsharp-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
    "smlsharp-$SMLSHARP_BOTTLE_SUFFIX"

#### uninstall smlsharp
$BREW uninstall smlsharp
