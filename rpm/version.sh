#!/bin/sh
. /etc/os-release
os=
case "$ID" in
  centos) os=el ;;
  fedora) os=fc ;;
esac
echo "$os$VERSION_ID"
