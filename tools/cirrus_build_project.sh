#!/usr/bin/env bash

set -euxo pipefail
shopt -s nullglob globstar

PROJECT=$1
CHANNEL=$2
OS=$3
ARCH=$4
SHOULD_BUILD=$5

echo "Checking VM specs..."
cat /etc/*-release
df -h
lscpu
free -m

echo "Installing rbm deps..."
add-apt-repository ppa:criu/ppa
apt-get update
apt-get install -y libyaml-libyaml-perl libtemplate-perl libio-handle-util-perl libio-all-perl libio-captureoutput-perl libjson-perl libpath-tiny-perl libstring-shellquote-perl libsort-versions-perl libdigest-sha-perl libdata-uuid-perl libdata-dump-perl libfile-copy-recursive-perl libfile-slurp-perl git runc criu

echo "Pulling rbm..."
make submodule-update

echo "Moving caches..."
if [[ -e "./fonts/.git" ]]; then
    echo "git_clones/fonts was cached, moving it to the right place..."
    mv ./fonts ./git_clones/fonts
else
    echo "git_clones/fonts was not cached."
    rm -rf ./fonts ./git_clones/fonts
fi
ls ./git_clones

echo "Checking if project is cached..."
OUTDIR="$(./rbm/rbm showconf $PROJECT output_dir --target $CHANNEL --target torbrowser-$OS-$ARCH)"
OUTFILE="$(./rbm/rbm showconf $PROJECT filename --target $CHANNEL --target torbrowser-$OS-$ARCH)"
if [[ -e "$OUTDIR/$OUTFILE" ]]; then
    echo "Project cache hit, skipping build."
    SHOULD_BUILD=0
else
    echo "Project cache miss, proceeding with build."
fi

# VM has 12 GB of free RAM.  Assuming each of the 4 logical cores takes 1 GB
# during build, that leaves us with 8 GB of unutilized RAM.  Alas, I'm not sure
# that's enough, so this isn't enabled right now.
#echo "Mounting tmpfs..."
#mount -t tmpfs -o size=8G,nr_inodes=40k,mode=1777 tmpfs ./tmp
#df -h

if [[ "$SHOULD_BUILD" -eq 1 ]]; then
    echo "Building project..."
    ./rbm/rbm build "$PROJECT" --target "$CHANNEL" --target torbrowser-"$OS"-"$ARCH"
else
    #echo "This is a cache-only task, skipping build."
    echo "Skipping build."
fi

echo "Moving caches..."
if [[ -e "git_clones/fonts" ]]; then
    echo "git_clones/fonts is ready to be cached, moving it to the right place..."
    mv git_clones/fonts ./
else
    echo "git_clones/fonts is not ready to be not cached."
    mkdir -p ./fonts
fi

# The cache has a size limit, so we need to clean useless data from it.  The
# container-images are very large and seem to be fairly harmless to remove.
# Maybe later if we have more pressure to shrink, we could remove the
# debootstrap-images too.
echo "Cleaning cache..."
rm -rfv out/container-image
