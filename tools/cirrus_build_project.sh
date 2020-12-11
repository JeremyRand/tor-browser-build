#!/usr/bin/env bash

set -euxo pipefail
shopt -s nullglob globstar

PROJECT=$1
CHANNEL=$2
OS=$3
ARCH=$4

echo "Checking VM specs..."
cat /etc/*-release
df -h
lscpu
free -m

echo "Installing rbm deps..."
apt-get install -y libyaml-libyaml-perl libtemplate-perl libio-handle-util-perl libio-all-perl libio-captureoutput-perl libjson-perl libpath-tiny-perl libstring-shellquote-perl libsort-versions-perl libdigest-sha-perl libdata-uuid-perl libdata-dump-perl libfile-copy-recursive-perl libfile-slurp-perl git runc

echo "Pulling rbm..."
make submodule-update

echo "Checking if project is cached..."
OUTDIR="$(./rbm/rbm showconf $PROJECT output_dir --target $CHANNEL --target torbrowser-$OS-$ARCH)"
OUTFILE="$(./rbm/rbm showconf $PROJECT filename --target $CHANNEL --target torbrowser-$OS-$ARCH)"
if [[ -e "$OUTDIR/$OUTFILE" ]]; then
    echo "Project cache hit, skipping build."
    exit 0
else
    echo "Project cache miss, proceeding with build."
fi

echo "Building project..."
./rbm/rbm build "$PROJECT" --target "$CHANNEL" --target torbrowser-"$OS"-"$ARCH"
