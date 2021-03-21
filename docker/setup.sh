#!/bin/sh

set -ex
cd `dirname $0`

for i in buildsmlsharp/*/Dockerfile; do
  dir=${i%/Dockerfile}
  os=${dir#buildsmlsharp/}
  v=`echo "$os" | sed 'y/./_/'`
  eval "v=\${$v-1}"
  [ "$v" -ne 1 ] || docker build -t "buildsmlsharp:$os" "$dir"
done
