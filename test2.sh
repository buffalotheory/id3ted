#!/bin/bash
# Bryant Hansen

# Description:
# this is a wrapper for test1.sh, which fetches a default mp3 file via http:// and 

# dependencies: wget, test1.sh

ME="$(basename "$0")"
USAGE="${ME} [ test_directory ]"

TEST_DIR="/tmp/"
[[ "$2" ]] && TEST_DIR="$2"
ORIGINAL_MEDIA_DIR="${TEST_DIR}/original_media"

# import (source) config settings
[[ test.conf ]] && [[ -f test.conf ]] && . test.conf

if [[ ! -d "$ORIGINAL_MEDIA_DIR" ]] ; then
	mkdir -p "$ORIGINAL_MEDIA_DIR"
fi
if [[ ! -d "$ORIGINAL_MEDIA_DIR" ]] ; then
	echo "ERROR: failed to find or create ORIGINAL_MEDIA_DIR $ORIGINAL_MEDIA_DIR" >&2
	exit 2
fi

# functions
function TRACE() {
	echo -e "$(date "+%Y%m%d_%H%M%S") ${ME}: $1" >&2
}

# assume passed unless some stage fails
test_result="passed"

# default test track:
# “Floss Suffers From Gamma Radiation” (by Blue Ducks)
# released via creativecommons.org under the Creative Commons free license
# http://freemusicarchive.org/music/download/e263a939f306c27e29cdbbd0a8b11a380b2d5628

MP3_URL="http://freemusicarchive.org/music/download/e263a939f306c27e29cdbbd0a8b11a380b2d5628"
MP3_FILE="${ORIGINAL_MEDIA_DIR}/e263a939f306c27e29cdbbd0a8b11a380b2d5628"
if [[ ! -f "${MP3_FILE}" ]] ; then
	if ! pushd "$ORIGINAL_MEDIA_DIR" ; then
		TRACE "ERROR: failed to change directory to ORIGINAL_MEDIA_DIR $ORIGINAL_MEDIA_DIR"
		exit 3
	fi
	wget http://freemusicarchive.org/music/download/"${MP3_FILE}"
	popd
fi

if [[ ! -f "${MP3_FILE}" ]] ; then
	TRACE "ERROR: failed to fetch mp3 test file $MP3_URL to local $MP3_FILE"
	exit 4
fi

./test1.sh "$MP3_FILE" || test_result="failed"
./test1.sh "$MP3_FILE" TBPM || test_result="failed"
./test1.sh "$MP3_FILE" TBPM 100.12 || test_result="failed"
./test1.sh "$MP3_FILE" TPUB "Test Publisher" || test_result="failed"

if [[ "$test_result" == "passed" ]] ; then
	TRACE "END: test passed"
	exit 0
else
	TRACE "END: test failed"
	exit 1
fi

