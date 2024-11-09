FROM ubuntu:noble
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive \
       apt-get install -y --no-install-recommends \
      devscripts \
      dput \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
