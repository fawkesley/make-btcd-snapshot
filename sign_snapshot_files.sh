#!/bin/sh -eux

DIRECTORY="$HOME/.gnupg"
SHA_FILE="${DIRECTORY}/sha256sums.txt"


make_sha256_checksums() {
    cd "${DIRECTORY}"
    FILES=$(find . -type f)

    sha256sum $FILES > "${SHA_FILE}"
    cd -
}


make_sha256_checksums
