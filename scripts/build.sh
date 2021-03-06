#!/usr/bin/env bash
#
# This script builds the application from source for multiple platforms.
set -e

export CGO_ENABLED=0

GIT_BUILDS=$(git rev-list --count $(git merge-base master HEAD)).$(git rev-list --count ^master HEAD)
GIT_MASTER_REV=$(git rev-parse --short master)
GIT_BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
VERSION="0.2.$GIT_BUILDS"

LDX_VERSION="github.com/hahutton/sasp/cmd.Version=$GIT_BUILDS"
LDX_MASTER="github.com/hahutton/sasp/cmd.MasterRev=$GIT_MASTER_REV"

if [ "$GIT_BRANCH_NAME" != "master" ]; then
    GIT_BRANCH_REV=$(git rev-parse --short HEAD)
	LDX_BRANCH_NAME="github.com/hahutton/sasp/cmd.BranchName=$GIT_BRANCH_NAME"
	LDX_BRANCH_REV="github.com/hahutton/sasp/cmd.BranchRev=$GIT_BRANCH_REV"
	export GOLDFLAGS="-X $LDX_VERSION -X $LDX_MASTER -X $LDX_BRANCH_REV -X $LDX_BRANCH_NAME"
else
	export GOLDFLAGS="-X $LDX_VERSION -X $LDX_MASTER"
fi

echo $GOLDFLAGS
# Get the parent directory of where this script is.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )/.." && pwd )"

# Change into that directory
cd "$DIR"

# Determine the arch/os combos we're building for
XC_ARCH=${XC_ARCH:-"386 amd64"}
XC_OS=${XC_OS:-"darwin linux windows"}

# Delete the old dir
echo "==> Removing old directory..."
rm -f bin/*
rm -rf pkg/*
mkdir -p bin/

# If it's dev mode, only build for ourself
if [ "${STOR_DEV}x" != "x" ]; then
    XC_OS=$(go env GOOS)
    XC_ARCH=$(go env GOARCH)
fi

# Build!
echo "==> Building..."
"`which gox`" \
    -os="${XC_OS}" \
    -arch="${XC_ARCH}" \
    -osarch="!darwin/arm !darwin/arm64" \
    -ldflags "${GOLDFLAGS}" \
    -output "pkg/{{.OS}}_{{.Arch}}/sasp" \
    -tags="${GOTAGS}" \
    .

# Move all the compiled things to the $GOPATH/bin
GOPATH=${GOPATH:-$(go env GOPATH)}
case $(uname) in
    CYGWIN*)
        GOPATH="$(cygpath $GOPATH)"
        ;;
esac
OLDIFS=$IFS
IFS=: MAIN_GOPATH=($GOPATH)
IFS=$OLDIFS

# Copy our OS/Arch to the bin/ directory
DEV_PLATFORM="./pkg/$(go env GOOS)_$(go env GOARCH)"
for F in $(find ${DEV_PLATFORM} -mindepth 1 -maxdepth 1 -type f); do
    cp ${F} bin/
    cp ${F} ${MAIN_GOPATH}/bin/
done

if [ "${STOR_DEV}x" = "x" ]; then
    # Zip and copy to the dist dir
    echo "==> Packaging..."
    for PLATFORM in $(find ./pkg -mindepth 1 -maxdepth 1 -type d); do
        OSARCH=$(basename ${PLATFORM})
        echo "--> ${OSARCH}"

        pushd $PLATFORM >/dev/null 2>&1
        zip ../${OSARCH}-${VERSION}.zip ./*
        popd >/dev/null 2>&1
    done
fi

# Done!
echo
echo "==> Results:"
ls -hl bin/
