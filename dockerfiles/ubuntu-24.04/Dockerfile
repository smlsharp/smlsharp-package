FROM ubuntu:noble
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
      dput \
      gnupg \
      llvm-18-dev \
      libsqlite3-dev \
      libgmp-dev \
      zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
ENV LLVM_VERSION 18
