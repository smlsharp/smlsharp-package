FROM almalinux:9
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
    && rm -rf /var/cache/dnf
ENV LLVM_VERSION 18
