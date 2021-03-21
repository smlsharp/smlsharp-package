# docker build -t buildsmlsharp:rawhide_rawhide .
#FROM registry.fedoraproject.org/fedora:rawhide
FROM fedora:rawhide
RUN : dnf -y update \
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
