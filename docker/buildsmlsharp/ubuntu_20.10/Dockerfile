# docker build -t buildsmlsharp:ubuntu_20.10 .
FROM ubuntu:20.10
RUN sed -i -e 's,archive.ubuntu.com,ftp.jaist.ac.jp/pub/Linux,' /etc/apt/sources.list \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
      apt-utils \
      build-essential \
      devscripts \
      lintian \
      xz-utils \
      debhelper \
      gnupg \
      llvm-11-dev \
      libsqlite3-dev \
      libgmp-dev \
      zlib1g-dev \
      libedit-dev \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*
