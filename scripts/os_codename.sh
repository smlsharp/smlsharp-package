#!/bin/sh -ex

os_codename () {
  case "$OS_NAME" in
    debian)
      case "${1:-$OS_VERSION}" in
        sid) OS_CODENAME=sid ;;
        10) OS_CODENAME=buster ;;
        11) OS_CODENAME=bullseye ;;
        12) OS_CODENAME=bookworm ;;
        *) return 1 ;;
      esac
      ;;
    ubuntu)
      case "${1:-$OS_VERSION}" in
        20.04) OS_CODENAME=focal ;;
        22.04) OS_CODENAME=jammy ;;
        24.04) OS_CODENAME=noble ;;
        *) return 1 ;;
      esac
      ;;
    fedora)
      OS_CODENAME=fc
      ;;
    almalinux|centos|rhel)
      OS_CODENAME=el
      ;;
    darwin)
      case "${1:-$OS_VERSION}" in
        11.*) OS_CODENAME=big_sur ;;
        12.*) OS_CODENAME=monterey ;;
        13.*) OS_CODENAME=ventura ;;
        14.*) OS_CODENAME=sonoma ;;
        15.*) OS_CODENAME=sequoia ;;
        *) return 1 ;;
      esac
      ;;
    *) return 1 ;;
  esac
}
