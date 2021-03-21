# docker build -t buildsmlsharp:centos_7 .
#
# NOTE: gpg (GnuPG) 2.0.22
FROM centos:centos7
RUN yum -y update \
    && yum install -y epel-release \
    && yum install -y \
      rpm-build \
      rpm-sign \
      rpmlint \
      createrepo \
      gnupg2 \
      llvm9.0-devel \
      make \
      gcc-c++ \
      sqlite-devel \
      gmp-devel \
    && yum clean all \
    && rm -rf /var/cache/yum/*
