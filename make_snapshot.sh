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

TODAY_DATE=$(date --iso-8601=date)

TMP_DIR=$(mktemp -d --suffix=.${TODAY_DATE} --tmpdir=${SNAPSHOT_DIR})


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

move_temp_dir() {
    mv "${TMP_DIR}" "${TODAY_SNAPSHOT}"

}

check_today_doesnt_exist

if find_most_recent_snapshot; then
    copy_previous_snapshot_to_today
else
    echo "No previous snapshot found, skipping incremental backup"
fi

sync_data_directory_to_today
move_temp_dir
