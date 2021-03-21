#!/bin/sh

: ${bottle_url:=}
: ${prerequisite:=}
: ${rbfile:=}
: ${source:=}
: ${no_cellar_any:=}
: ${USR_LOCAL:=/usr/local}
[ -n "$rbfile" -a -n "$source" ] || exit
unset HOMEBREW_VERBOSE
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_GITHUB_API=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_ANALYTICS=1
set -ex

## reserve stdout for the result
exec 3>&1 1>&2

## create the working directory
tmp=`mktemp -d`
trap 'rm -rf "$tmp"' EXIT
trap 'exit 127' INT QUIT
PATH="$tmp/bin:/usr/bin:/bin"

## clone the Homebrew system
git clone --depth=1 file://"$USR_LOCAL"/Homebrew "$tmp/Homebrew"
mkdir "$tmp/bin" "$tmp/http" "$tmp/cache" "$tmp/out"
ln -s ../Homebrew/bin/brew "$tmp/bin"
git clone --depth=1 \
  file://"$USR_LOCAL"/Homebrew/Library/Taps/homebrew/homebrew-core \
  "$tmp/Homebrew/Library/Taps/homebrew/homebrew-core"

## tap the prerequisite
formuladir="$tmp/Homebrew/Library/Taps/smlsharp/homebrew-smlsharp/Formula"
mkdir -p "$formuladir"
if [ -s "$prerequisite" ]; then
  (cd "$formuladir" && pax -r '*.rb') < "$prerequisite"
  for i in "$formuladir"/*.rb; do
    root_url=`sed '/^ *root_url .*https/!d;s|^.*"https://\(.*\)".*$|\1|' "$i"`
    test -n "$root_url"
    mkdir -p "$tmp/http/$root_url"
    (cd "$tmp/http/$root_url" && pax -r '*.bottle.tar.gz') < "$prerequisite"
  done
fi

## prepare the rbfile and source
targetname=${rbfile##*/}
targetname=${targetname%.rb}
targetname=${targetname%%-*}
cp "$rbfile" "$formuladir/$targetname.rb"
url=`sed '/^ *url .*https/!d;s|^.*"https://\(.*\)".*$|\1|' "$rbfile"`
test -n "$url"
mkdir -p "$tmp/http/${url%/*}"
cp "$source" "$tmp/http/$url"

## install prerequisite formulae
for name; do
  case "$name" in
    *:)
      export HOMEBREW_ARTIFACT_DOMAIN="file://$tmp/http"
      export HOMEBREW_CACHE="$tmp/cache"
      name=${name%:}
      ;;
    *)
      unset HOMEBREW_ARTIFACT_DOMAIN
      unset HOMEBREW_CACHE
      ;;
  esac
  brew install --force-bottle "$name"
done

## install the target formula and build the bottle
export HOMEBREW_ARTIFACT_DOMAIN="file://$tmp/http"
export HOMEBREW_CACHE="$tmp/cache"
export HOMEBREW_VERBOSE=1
brew install -v --build-bottle "$targetname"

## edit the formula
sed -i '' '/##D##/d;s/##K##//' "$formuladir/$targetname.rb"
mtime=`date -r "$tmp/opt/$targetname/.brew/$targetname.rb" '+%Y%m%d%H%M.%S'`
cp "$formuladir/$targetname.rb" "$tmp/opt/$targetname/.brew/$targetname.rb"
touch -m -t "$mtime" "$tmp/opt/$targetname/.brew/$targetname.rb"

## pour the bottle
(cd "$tmp/out" && brew bottle --json --root-url "$bottle_url" "$targetname")
for i in "$tmp/out"/*; do
  j=`echo "$i" | sed s/--/-/`
  mv "$i" "$j"
done

## merge bottle information to the formula
brew bottle --no-commit --merge --write "$tmp/out"/*.json
if [ -n "$no_cellar_any" ]; then
  sed -i '' 's/ *cellar: *:any, */ /' "$formuladir/$targetname.rb"
fi

## archive the result
pax -w -s '|^.*/||' \
  "$tmp/out/"*.bottle.tar.gz \
  "$formuladir/$targetname.rb" \
  1>&3
