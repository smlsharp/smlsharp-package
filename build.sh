#!/bin/sh
BASE=$(dirname "$0")
: ${BUILD:=./build}
: ${REPOS:=./repos}
set -ex

if [ ! -d "$BUILD" ]; then
  mkdir "$BUILD"
  chmod 1777 "$BUILD"
fi

: ${OS_ARCH:=amd64}  # amd64 or aarch64
BUILD_PACKAGE=$1
BUILD_TARGET=$2

# -------- version information --------

. "$BASE/scripts/massivethreads/release.sh"
. "$BASE/scripts/smlsharp/release.sh"

#### along with the official distributions
MVTH_DEBVERSION=1.02-4
SMLSHARP_DEBVERSION=4.1.0-1

# -------- utilities --------

. "$BASE/scripts/os_codename.sh"

#### GNU tar is required
: ${TAR:=tar}

need_build () {
  case "$BUILD_PACKAGE:$BUILD_TARGET" in
    :) ;;
    $1:) ;;
    :${2:-$OS_NAME}) ;;
    $1:${2:-$OS_NAME}) ;;
    *) return 1 ;;
  esac
}

download () {
  curl -f -L -o "$1" "$2"
  hash=$(sha256sum "$1")
  if [ " ${hash%% *}" != " $3" ]; then
    rm -f "$1"
    exit 1
  fi
}

# -------- containers --------

: ${PODMAN:=podman}

load_buildsmlsharp () {
  IMAGE_TAG=${1:-$OS_NAME-${OS_VERSION}}
  IMAGE_FILE="buildsmlsharp_${IMAGE_TAG}_${OS_ARCH}.tar"
  IMAGE_ID="localhost/buildsmlsharp:$IMAGE_TAG"
  if [ ! -f "$BUILD/$IMAGE_FILE" ]; then
    (
      cd "$BASE/dockerfiles/$IMAGE_TAG"
      $PODMAN build -t "$IMAGE_ID" --platform="linux/$OS_ARCH" .
    )
    $PODMAN save -o "$BUILD/$IMAGE_FILE" "$IMAGE_ID"
  elif [ -z "$($PODMAN images -n "$IMAGE_ID")" ]; then
    $PODMAN load -i "$BUILD/$IMAGE_FILE"
  fi
}

remove_buildsmlsharp () {
  $PODMAN rmi "localhost/buildsmlsharp:$IMAGE_TAG" 2> /dev/null || :
}

run_buildsmlsharp () {
  load_buildsmlsharp "$1"
  shift 1
  $PODMAN run --rm --platform="linux/$OS_ARCH" --sig-proxy=false \
          -v "$BUILD:/build:rw" \
          -v "$BASE/scripts:/scripts:ro" \
          -v "$BASE/keys:/keys:ro" \
          -w /root \
          -e "MVTH_BASE_VERSION=$MVTH_BASE_VERSION" \
          -e "MVTH_FULL_VERSION=$MVTH_FULL_VERSION" \
          -e "SMLSHARP_VERSION=$SMLSHARP_VERSION" \
          -e "SMLSHARP_BASE_VERSION=$SMLSHARP_BASE_VERSION" \
          -e "SMLSHARP_FULL_VERSION=$SMLSHARP_FULL_VERSION" \
          -e "OS_NAME=$OS_NAME" \
          -e "OS_VERSION=$OS_VERSION" \
          -e "OS_ARCH=$OS_ARCH" \
          -e "RPM_OS_ARCH=$RPM_OS_ARCH" \
          "localhost/buildsmlsharp:$IMAGE_TAG" \
          "$@"
}

run_buildsmlsharp_with_gpgkey () {
  load_buildsmlsharp "$1"
  shift 1
  gpg --batch --decrypt "$BASE/keys/signing-key.asc" \
  | $PODMAN run --rm -i --platform="linux/$OS_ARCH" --sig-proxy=false \
            -v "$BUILD:/build:rw" \
            -v "$BASE/scripts:/scripts:ro" \
            -v "$BASE/keys:/keys:ro" \
            -v "$REPOS:/repos:ro" \
            --tmpfs /root/.gnupg:size=1m,mode=700 \
            -w /root \
            -e "OS_LIST=$OS_LIST" \
            localhost/buildsmlsharp:"$IMAGE_TAG" \
            "$@"
}

# -------- source packages --------

fetch_smlsharp_src () {
  SMLSHARP_FILENAME=${SMLSHARP_URL##*/}
  if [ ! -f "$BUILD/$SMLSHARP_FILENAME" ]; then
    download "$BUILD/$SMLSHARP_FILENAME" "$SMLSHARP_URL" "$SMLSHARP_SHA256"
  fi
}

fetch_massivethreads_src () {
  MVTH_FILENAME="massivethreads-$MVTH_VERSION.tar.gz"
  if [ ! -f "$BUILD/$MVTH_FILENAME" ]; then
    download "$BUILD/$MVTH_FILENAME" "$MVTH_URL" "$MVTH_SHA256"
  fi
}

# -------- deb packages --------

fetch_massivethreads_deb () {
  if [ ! -f "$BUILD/massivethreads_$MVTH_DEBVERSION.deb-src.tar" ]; then
    run_buildsmlsharp debian-sid sh /scripts/massivethreads/deb/fetch.sh
  fi
}

fetch_smlsharp_deb () {
  if [ ! -f "$BUILD/smlsharp_$SMLSHARP_DEBVERSION.deb-src.tar" ]; then
    run_buildsmlsharp debian-sid sh /scripts/smlsharp/deb/fetch.sh
  fi
}

build_massivethreads_deb () {
  MVTH_BASE_VERSION="$MVTH_DEBVERSION"
  MVTH_FULL_VERSION=$( \
    sed '/^+massivethreads /!d;s/^.*(//;s/).*$//;q' \
        "$BASE/scripts/massivethreads/deb/debian-changelog.diff" \
  )${DEB_SUFFIX#v1}
  if [ ! -f "$BUILD/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" ]; then
    if need_build massivethreads; then
      fetch_massivethreads_src
      fetch_massivethreads_deb
      :
      : "**** Build MassiveThreads on $OS_NAME $OS_VERSION ****"
      :
      run_buildsmlsharp '' sh /scripts/massivethreads/deb/build.sh
    elif need_build smlsharp; then
      $TAR --skip-old-files \
           -C "$REPOS/$OS_NAME/pool/l/libmassivethreads" \
           -cf "$BUILD/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
           "libmassivethreads0-${MVTH_FULL_VERSION}_${OS_ARCH}.deb" \
           "libmassivethreads-dev-${MVTH_FULL_VERSION}_${OS_ARCH}.deb"
    fi
  fi
}

build_smlsharp_deb () {
  SMLSHARP_VERSION_DEB=$(echo "$SMLSHARP_VERSION" | sed 'y/-/~/')
  SMLSHARP_BASE_VERSION="$SMLSHARP_DEBVERSION"
  SMLSHARP_FULL_VERSION="$SMLSHARP_VERSION_DEB-0$DEB_SUFFIX"
  if need_build smlsharp; then
    if [ ! -f "$BUILD/smlsharp-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" ]; then
      fetch_smlsharp_src
      fetch_smlsharp_deb
      :
      : "**** Build SML# on $OS_NAME $OS_VERSION ****"
      :
      run_buildsmlsharp '' sh /scripts/smlsharp/deb/build.sh
    fi
  fi
}

# ------- Debian -------

OS_NAME=debian
for OS_VERSION in sid 12 11; do
  case "$OS_VERSION" in
    sid) DEB_SUFFIX="v1" ;; # should supersude "ubuntu1"
    *) DEB_SUFFIX="v1~$OS_NAME$OS_VERSION+1" ;;
  esac

  build_massivethreads_deb
  build_smlsharp_deb

  if need_build massivethreads; then
    mkdir -p "$REPOS/$OS_NAME/pool/l/libmassivethreads"
    $TAR --skip-old-files \
         -C "$REPOS/$OS_NAME/pool/l/libmassivethreads" \
         -xf "$BUILD/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
         "libmassivethreads0_${MVTH_FULL_VERSION}_${OS_ARCH}.deb" \
         "libmassivethreads-dev_${MVTH_FULL_VERSION}_${OS_ARCH}.deb"
    mkdir -p "$REPOS/$OS_NAME/pool/m/massivethreads"
    $TAR --skip-old-files \
         -C "$REPOS/$OS_NAME/pool/m/massivethreads" \
         -xf "$BUILD/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
         "massivethreads_${MVTH_FULL_VERSION%-*}.orig.tar.gz" \
         "massivethreads_${MVTH_FULL_VERSION}.debian.tar.xz" \
         "massivethreads_${MVTH_FULL_VERSION}.dsc" \
         "massivethreads_${MVTH_FULL_VERSION}_source.buildinfo" \
         "massivethreads_${MVTH_FULL_VERSION}_source.changes"
  fi

  if need_build smlsharp; then
    mkdir -p "$REPOS/$OS_NAME/pool/s/smlsharp"
    $TAR --skip-old-files \
         -C "$REPOS/$OS_NAME/pool/s/smlsharp" \
         -xf "$BUILD/smlsharp-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
         "smlsharp_${SMLSHARP_VERSION_DEB}.orig.tar.gz" \
         "smlsharp_${SMLSHARP_FULL_VERSION}.debian.tar.xz" \
         "smlsharp_${SMLSHARP_FULL_VERSION}.dsc" \
         "smlsharp_${SMLSHARP_FULL_VERSION}_source.buildinfo" \
         "smlsharp_${SMLSHARP_FULL_VERSION}_source.changes" \
         "smlsharp_${SMLSHARP_FULL_VERSION}_${OS_ARCH}.deb"
  fi
done

# ------- Ubuntu --------

OS_NAME=ubuntu
for OS_VERSION in 24.04 22.04; do
  DEB_SUFFIX="v1ppa1~$OS_NAME$OS_VERSION.1"

  build_massivethreads_deb
  build_smlsharp_deb

  if need_build massivethreads; then
    mkdir -p "$REPOS/$OS_NAME/pool/m/massivethreads"
    $TAR --skip-old-files \
         -C "$REPOS/$OS_NAME/pool/m/massivethreads" \
         -xf "$BUILD/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
         "massivethreads_${MVTH_FULL_VERSION%-*}.orig.tar.gz" \
         "massivethreads_${MVTH_FULL_VERSION}.debian.tar.xz" \
         "massivethreads_${MVTH_FULL_VERSION}.dsc" \
         "massivethreads_${MVTH_FULL_VERSION}_source.buildinfo" \
         "massivethreads_${MVTH_FULL_VERSION}_source.changes"
  fi

  if need_build smlsharp; then
    mkdir -p "$REPOS/$OS_NAME/pool/s/smlsharp"
    $TAR --skip-old-files \
         -C "$REPOS/$OS_NAME/pool/s/smlsharp" \
         -xf "$BUILD/smlsharp-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
         "smlsharp_${SMLSHARP_VERSION_DEB}.orig.tar.gz" \
         "smlsharp_${SMLSHARP_FULL_VERSION}.debian.tar.xz" \
         "smlsharp_${SMLSHARP_FULL_VERSION}.dsc" \
         "smlsharp_${SMLSHARP_FULL_VERSION}_source.buildinfo" \
         "smlsharp_${SMLSHARP_FULL_VERSION}_source.changes"
  fi
done

# -------- rpm packages --------

rawhide_release () {
  if [ -f "$BUILD/rawhide-release.txt" ]; then
    RPM_RELEASE=$(cat "$BUILD/rawhide-release.txt")
  else
    load_buildsmlsharp fedora-rawhide
    RPM_RELEASE=$( \
      $PODMAN run --rm --platform="linux/$OS_ARCH" --sig-proxy=false \
                  "localhost/buildsmlsharp:$IMAGE_TAG" \
                  cat /etc/system-release \
    )
    RPM_RELEASE=$(perl -e '$ARGV[0]=~/(\d+)/;print $1' "$RPM_RELEASE")
    echo "$RPM_RELEASE" > "$BUILD/rawhide-release.txt"
  fi
}

rpm_release () {
  case "$OS_VERSION" in
    rawhide) rawhide_release ;;
    *) RPM_RELEASE=$OS_VERSION ;;
  esac
}

rpm_os_arch () {
  case "$OS_ARCH" in
    amd64) RPM_OS_ARCH=x86_64 ;;
    aarch64) RPM_OS_ARCH=aarch64 ;;
    *) exit 1
  esac
}

rpmspec_version () {
  RPMSPEC=$1
  RPMSPEC_VERSION=$(sed '/^Version: /!d;s/Version: *//' "$RPMSPEC")
  RPMSPEC_RELEASE=$(sed '/^Release: /!d;s/Release: *//;s/%.*$//' "$RPMSPEC")
  RPMSPEC_FULL_VERSION="$RPMSPEC_VERSION-$RPMSPEC_RELEASE"
  RPMSPEC_FULL_VERSION="$RPMSPEC_FULL_VERSION.$OS_CODENAME$RPM_RELEASE"
}

build_massivethreads_rpm () {
  rpmspec_version "$BASE/scripts/massivethreads/rpm/massivethreads.spec"
  MVTH_FULL_VERSION=$RPMSPEC_FULL_VERSION
  if [ ! -f "$BUILD/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" ]; then
    if need_build massivethreads; then
      fetch_massivethreads_src
      :
      : "**** Build MassiveThreads on $OS_NAME $OS_VERSION ****"
      :
      run_buildsmlsharp '' sh /scripts/massivethreads/rpm/build.sh
    elif need_build smlsharp; then
      $TAR --skip-old-files \
           -C "$REPOS/$OS_NAME/$OS_VERSION/$RPM_OS_ARCH/Packages/m" \
           -cf "$BUILD/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
           "massivethreads-$MVTH_FULL_VERSION.$RPM_OS_ARCH.rpm" \
           "massivethreads-devel-$MVTH_FULL_VERSION.$RPM_OS_ARCH.rpm"
    fi
  fi
}

build_smlsharp_rpm () {
  rpmspec_version "$BASE/scripts/smlsharp/rpm/smlsharp.spec"
  SMLSHARP_FULL_VERSION=$RPMSPEC_FULL_VERSION
  if need_build smlsharp; then
    if [ ! -f "$BUILD/smlsharp-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" ]; then
      fetch_smlsharp_src
      :
      : "**** Build SML# on $OS_NAME $OS_VERSION ****"
      :
      run_buildsmlsharp '' sh /scripts/smlsharp/rpm/build.sh
    fi
  fi
}

build_smlsharp_release_rpm () {
  rpmspec_version \
    "$BASE/scripts/smlsharp-release/rpm/smlsharp-release-$OS_NAME.spec"
  SMLREL_FULL_VERSION="$RPMSPEC_VERSION-$RPMSPEC_RELEASE"
  if need_build smlsharp-release; then
    if [ ! -f "$BUILD/smlsharprelease-$OS_NAME-$OS_VERSION.tar" ]; then
      run_buildsmlsharp '' sh /scripts/smlsharp-release/rpm/build.sh
    fi
  fi
}

# -------- Fedora & AlmaLinux --------

for NAME_VERSION in fedora:rawhide almalinux:9 almalinux:8; do
  OS_NAME=${NAME_VERSION%:*}
  OS_VERSION=${NAME_VERSION#*:}
  if need_build massivethreads || need_build smlsharp; then
    os_codename
    rpm_os_arch
    rpm_release
  fi

  build_massivethreads_rpm
  build_smlsharp_rpm

  if need_build massivethreads; then
    mkdir -p "$REPOS/$OS_NAME/$OS_VERSION/$RPM_OS_ARCH/Packages/m"
    mkdir -p "$REPOS/$OS_NAME/$OS_VERSION/source/Packages/m"
    $TAR --skip-old-files \
         -C "$REPOS/$OS_NAME/$OS_VERSION/$RPM_OS_ARCH/Packages/m" \
         -xf "$BUILD/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
         "massivethreads-$MVTH_FULL_VERSION.$RPM_OS_ARCH.rpm" \
         "massivethreads-doc-$MVTH_FULL_VERSION.noarch.rpm" \
         "massivethreads-devel-$MVTH_FULL_VERSION.$RPM_OS_ARCH.rpm" \
         "massivethreads-dl-$MVTH_FULL_VERSION.$RPM_OS_ARCH.rpm" \
         "massivethreads-dr-$MVTH_FULL_VERSION.$RPM_OS_ARCH.rpm" \
         "massivethreads-ld-$MVTH_FULL_VERSION.$RPM_OS_ARCH.rpm"
    $TAR --skip-old-files \
         -C "$REPOS/$OS_NAME/$OS_VERSION/source/Packages/m" \
         -xf "$BUILD/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
         "massivethreads-$MVTH_FULL_VERSION.src.rpm"
  fi

  if need_build smlsharp; then
    mkdir -p "$REPOS/$OS_NAME/$OS_VERSION/$RPM_OS_ARCH/Packages/s"
    mkdir -p "$REPOS/$OS_NAME/$OS_VERSION/source/Packages/s"
    $TAR --skip-old-files \
         -C "$REPOS/$OS_NAME/$OS_VERSION/$RPM_OS_ARCH/Packages/s" \
         -xf "$BUILD/smlsharp-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
         "smlsharp-$SMLSHARP_FULL_VERSION.$RPM_OS_ARCH.rpm" \
         "smlsharp-smlformat-$SMLSHARP_FULL_VERSION.$RPM_OS_ARCH.rpm" \
         "smlsharp-smllex-$SMLSHARP_FULL_VERSION.$RPM_OS_ARCH.rpm" \
         "smlsharp-smlyacc-$SMLSHARP_FULL_VERSION.$RPM_OS_ARCH.rpm"
    $TAR --skip-old-files \
         -C "$REPOS/$OS_NAME/$OS_VERSION/source/Packages/s" \
         -xf "$BUILD/smlsharp-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
         "smlsharp-$SMLSHARP_FULL_VERSION.src.rpm"
  fi
done

for NAME_VERSION in fedora:rawhide almalinux:8; do
  OS_NAME=${NAME_VERSION%:*}
  OS_VERSION=${NAME_VERSION#*:}

  build_smlsharp_release_rpm

  if need_build smlsharp-release; then
    mkdir -p "$REPOS/$OS_NAME"
    $TAR --skip-old-files \
         -C "$REPOS/$OS_NAME" \
         -xf "$BUILD/smlsharprelease-$OS_NAME-$OS_VERSION.tar" \
         "smlsharp-release-$OS_NAME-$SMLREL_FULL_VERSION.noarch.rpm" \
         "smlsharp-release-$OS_NAME-$SMLREL_FULL_VERSION.src.rpm"
  fi
done

# ------- APT repositories --------

OS_LIST=
for OS_NAME in debian ubuntu; do
  if need_build repos; then
    OS_LIST="$OS_LIST $OS_NAME"
  fi
done

if [ -n "$OS_LIST" ]; then
  if [ ! -f "$BUILD/deb_build_repository.tar" ]; then
    run_buildsmlsharp_with_gpgkey debian-sid sh /scripts/deb_build_repository.sh
  fi
  $TAR -xf "$BUILD/deb_build_repository.tar"
fi

# -------- RPM repositories --------

OS_LIST=
for OS_NAME in fedora almalinux; do
  if need_build repos; then
    OS_LIST="$OS_LIST $OS_NAME"
  fi
done

if [ -n "$OS_LIST" ]; then
  if [ ! -f "$BUILD/rpm_build_repository.tar" ]; then
    run_buildsmlsharp_with_gpgkey \
      fedora-rawhide sh /scripts/rpm_build_repository.sh
  fi

  #### remove old repodata
  $TAR -tf "$BUILD/rpm_build_repository.tar" \
  | sed 's,/[^/]*$,,;/\/repodata$/!d' \
  | uniq \
  | while read i; do rm -f "$i"/*; done

  $TAR -xf "$BUILD/rpm_build_repository.tar"
fi

# -------- macOS Homebrew --------

formula_info () {
  FORMULA="$BASE/homebrew-smlsharp/Formula/$1.rb"
  FORMULA_VERSION=${2:-$(sed '/version/!d;s/^[^"]*"//;s/".*$//;q' "$FORMULA")}
  FORMULA_REVISION=$(sed '/revision/!d;s/^.* //' "$FORMULA")
  FORMULA_FULL_VERSION="${FORMULA_VERSION}_${FORMULA_REVISION}"
  FORMULA_FULL_VERSION=${FORMULA_FULL_VERSION%_}
  case "$OS_ARCH" in
    aarch64) BOTTLE_CODENAME="arm64_$OS_CODENAME" ;;
    *) BOTTLE_CODENAME=$OS_CODENAME ;;
  esac
  BOTTLE_SUFFIX="$FORMULA_FULL_VERSION.$BOTTLE_CODENAME.bottle.tar.gz"
}

build_massivethreads_mac () {
  formula_info massivethreads
  MVTH_BOTTLE_SUFFIX=$BOTTLE_SUFFIX
  if need_build massivethreads; then
    if [ ! -f "$BUILD/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" ]; then
      BUILD=$BUILD \
      MVTH_BOTTLE_SUFFIX=$MVTH_BOTTLE_SUFFIX \
      OS_NAME=$OS_NAME \
      OS_VERSION=$OS_VERSION \
      OS_ARCH=$OS_ARCH \
      sh "$BASE/scripts/massivethreads/mac/build.sh"
    fi
  fi
}

build_smlsharp_mac () {
  formula_info smlsharp "$SMLSHARP_VERSION"
  SMLSHARP_BOTTLE_SUFFIX=$BOTTLE_SUFFIX
  if need_build smlsharp; then
    if [ ! -f "$BUILD/smlsharp-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" ]; then
      BUILD=$BUILD \
      MVTH_BOTTLE_SUFFIX=$MVTH_BOTTLE_SUFFIX \
      SMLSHARP_BOTTLE_SUFFIX=$SMLSHARP_BOTTLE_SUFFIX \
      OS_NAME=$OS_NAME \
      OS_VERSION=$OS_VERSION \
      OS_ARCH=$OS_ARCH \
      sh "$BASE/scripts/smlsharp/mac/build.sh"
    fi
  fi
}

if [ " $(uname -s)" = ' Darwin' ]; then
  OS_NAME=darwin
  if need_build massivethreads || need_build smlsharp; then
    OS_VERSION=$(sw_vers --productVersion)
    os_codename
  fi

  build_massivethreads_mac
  build_smlsharp_mac

  if need_build massivethreads; then
    mkdir -p "$REPOS/homebrew"
    $TAR --skip-old-files \
         -C "$REPOS/homebrew" \
         -xf "$BUILD/massivethreads-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
         "massivethreads-$MVTH_BOTTLE_SUFFIX"
  fi

  if need_build smlsharp; then
    mkdir -p "$REPOS/homebrew"
    $TAR --skip-old-files \
         -C "$REPOS/homebrew" \
         -xf "$BUILD/smlsharp-$OS_NAME-$OS_VERSION-$OS_ARCH.tar" \
         "smlsharp-$SMLSHARP_BOTTLE_SUFFIX"
  fi

  if [ -d "$BUILD/homebrew/Library/Taps/smlsharp/homebrew-smlsharp" ]; then
    TAP=$(realpath "$BUILD/homebrew/Library/Taps/smlsharp/homebrew-smlsharp")
    (cd "$BASE/homebrew-smlsharp" && git pull "$TAP")
  fi
fi

# -------- end --------
: Done.
