FROM ubuntu:focal
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive \
       apt-get install -y --no-install-recommends \
      apt-utils \
      build-essential \
      devscripts \
      lintian \
      debhelper \
      libdistro-info-perl \
      gnupg \
      llvm-12-dev \
      libsqlite3-dev \
      libgmp-dev \
      zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
ENV LLVM_VERSION 12
