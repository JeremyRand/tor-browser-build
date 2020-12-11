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

# VM has 12 GB of free RAM.  Assuming each of the 4 logical cores takes 1 GB
# during build, that leaves us with 8 GB of unutilized RAM.  Alas, I'm not sure
# that's enough, so this isn't enabled right now.
#echo "Mounting tmpfs..."
#mount -t tmpfs -o size=8G,nr_inodes=40k,mode=1777 tmpfs ./tmp
#df -h

echo "Building project..."
./rbm/rbm build "$PROJECT" --target "$CHANNEL" --target torbrowser-"$OS"-"$ARCH"

# The cache has a size limit, so we need to clean useless data from it.  The
# runc images are very large and seem to be fairly harmless to remove.
echo "Cleaning cache..."
rm -rfv out/container-image out/debootstrap-image
