# docker build -t buildsmlsharp:docker_sid .
FROM debian:sid
RUN sed -i -e 's,deb.debian.org,ftp.jaist.ac.jp/pub/Linux,' /etc/apt/sources.list \
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
