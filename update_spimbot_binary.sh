#!/bin/bash

set -e

ARGC=$#
REPO_DIR=$1
BINARY_VERSION=$2

DEST_PATH=~/.local/bin/QtSpimbot

if [ $ARGC -ne 2 ]; then
    echo "Invalid usage, exiting..."
    echo "Usage: ./update_spimbot_binary.sh <path to spimbot_binaries repo> <binary version>"
    echo "Example: ./update_spimbot_binary.sh ~/.spimbot/spimbot_binaries linux_x86_64"
    exit 1
fi;

if [ ! -d $REPO_DIR ]; then
    echo "REPO_DIR is not a valid directory, exiting..."
    exit 2
fi;

if [ ! -d $REPO_DIR/$BINARY_VERSION ]; then
    echo "BINARY_VERSION is not a directory in REPO_DIR, exiting..."
    exit 3
fi;

pushd $REPO_DIR > /dev/null

git remote update > /dev/null
commitdiff=$(git rev-list HEAD...origin/main --count)

if [ $commitdiff -gt 0 ]; then
    echo "New remote commit detected, pulling + installing..."
    git checkout main && git pull
    cp $BINARY_VERSION/QtSpimbot $DEST_PATH
    echo "Installed new binary"
fi;

popd > /dev/null
