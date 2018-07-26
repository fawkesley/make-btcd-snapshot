#!/bin/sh -eux

# We end up with snapshots in directories like:
#
# ~/snapshots/2018-07-21
# ~/snapshots/2018-07-22
# ~/snapshots/2018-07-23
#
# Thanks to http://www.admin-magazine.com/Articles/Using-rsync-for-Backups/(offset)/2

DATA_DIR="$HOME/.btcd/data"
SNAPSHOT_DIR="$HOME/snapshots"
THIS_SCRIPT=$0
THIS_DIR=$(dirname ${THIS_SCRIPT})


TODAY_DATE=$(date --iso-8601=date)

TMP_DIR=$(mktemp -d --suffix=.${TODAY_DATE} --tmpdir=${SNAPSHOT_DIR})
SHA_FILENAME="${TMP_DIR}/sha256sums.txt"



check_today_doesnt_exist() {

    TODAY_SNAPSHOT="${SNAPSHOT_DIR}/${TODAY_DATE}"

    if [ -d "${TODAY_SNAPSHOT}" ]; then
        echo "Snapshot dir already exists: ${TODAY_SNAPSHOT}"
        exit 1
    fi
}

find_most_recent_snapshot() {
    PREVIOUS_SNAPSHOT=$(find ${SNAPSHOT_DIR} -maxdepth 1 -name '????-??-??' -type d | sort | tail -n 1)

    if [ -d "${PREVIOUS_SNAPSHOT}" ]; then
	return 0
	# means success
    else
	return 1
    fi
}

copy_previous_snapshot_to_today() {
    cd "${PREVIOUS_SNAPSHOT}"
    cp --archive --link . "${TMP_DIR}"
    cd -
}

sync_data_directory_to_today() {
    nice --10 rsync --progress --archive --delete "${DATA_DIR}/" "${TMP_DIR}"
}

make_sha256_checksums() {
    cd "${TMP_DIR}"
    FILES=$(find . -type f | sort)

    sha256sum $FILES > "${SHA_FILENAME}"
    cd -
}

sign_sha256_file() {
    GPG_TEMP=$(mktemp -d)
    export GNUPGHOME=${GPG_TEMP}
    gpg --import "${THIS_DIR}/signing_key/public.asc"
    gpg --import "${THIS_DIR}/signing_key/secret.asc"
    gpg --yes --output "${SHA_FILENAME}.sig" --detach-sig "${SHA_FILENAME}"
    rm -rf "${GPG_TEMP}"
}

move_temp_dir() {
    mv "${TMP_DIR}" "${TODAY_SNAPSHOT}"
}

change_permissions() {
    chmod -R o+rx "${TODAY_SNAPSHOT}"
}


check_today_doesnt_exist

if find_most_recent_snapshot; then
    copy_previous_snapshot_to_today
else
    echo "No previous snapshot found, skipping incremental backup"
fi

sync_data_directory_to_today
make_sha256_checksums
sign_sha256_file
move_temp_dir
change_permissions
