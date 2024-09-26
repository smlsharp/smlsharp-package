#!/bin/sh -ex

#### the following must be given
test -n "$BASE"
test -n "$BUILD"
test -n "$OS_ARCH"

#### brew must be run on OS_ARCH
case "$OS_ARCH" in
  aarch64) BREW='arch -arm64 brew' ;;
  amd64) BREW='arch -x86_64 brew' ;;
  *) exit 1 ;;
esac

#### setup Homebrew
export HOMEBREW_VERBOSE=
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_GITHUB_API=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_ANALYTICS=1
PATH=/usr/bin:/bin

if [ -d "$BUILD/homebrew" ]; then
  eval "$("$BUILD/homebrew/bin/brew" shellenv)"
else
  git clone https://github.com/Homebrew/brew.git "$BUILD/homebrew"
  eval "$("$BUILD/homebrew/bin/brew" shellenv)"
  $BREW update --force
fi

#### tap homebrew-smlsharp repository
$BREW tap smlsharp/smlsharp "$(realpath "$BASE/homebrew-smlsharp")"
(
  cd "$BUILD/homebrew/Library/Taps/smlsharp/homebrew-smlsharp/.git"
  git config --local commit.gpgsign false
)

#### utilities
FORMULADIR="$HOMEBREW_PREFIX/Library/Taps/smlsharp/homebrew-smlsharp/Formula"

homebrew_add_cache () {
  export HOMEBREW_CACHE
  mkdir -p "$HOMEBREW_CACHE/downloads"
  hash=$(printf '%s' "$2" | openssl dgst -sha256 | sed 's/^.*=  *//')
  cp "$1" "$HOMEBREW_CACHE/downloads/$hash--${3:-${1##*/}}"
}
