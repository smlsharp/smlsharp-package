FROM fedora:rawhide
RUN dnf -y update \
    && dnf install -y \
      rpm-build \
      rpm-sign \
      rpmlint \
      createrepo \
      llvm18-devel \
      make \
      gcc-c++ \
      sqlite-devel \
      gmp-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf
ENV LLVM_VERSION 18
