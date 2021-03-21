# docker build -t buildsmlsharp:fedora_33 .
FROM fedora:33
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
