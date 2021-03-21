# docker build -t buildsmlsharp:centos_8 .
#
# NOTE: gpg (GnuPG) 2.2.9
FROM centos:centos8
RUN dnf -y update \
    && dnf install -y \
      rpm-build \
      rpm-sign \
      rpmlint \
      createrepo \
      llvm-devel \
      make \
      gcc-c++ \
      sqlite-devel \
      gmp-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf/*
