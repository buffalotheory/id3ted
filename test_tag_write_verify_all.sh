#!/bin/sh
# Bryant Hansen

# writable fields generated by:
# ./id3ted --frame-list | grep "^\ \ \*" | while read a b c ; do echo $b ; done > writable_fields.lst

ME="$(basename "$0")"
USAGE="${ME} [ test_directory ]"


# defaults
BIN=./id3ted
TEST_DIR="/tmp/"
[[ "$2" ]] && TEST_DIR="$2"
ORIGINAL_MEDIA_DIR="${TEST_DIR}/original_media"


# functions
function TRACE() {
	echo -e "$(date "+%Y%m%d_%H%M%S") ${ME}: $1" >&2
}


if [[ ! -d "$ORIGINAL_MEDIA_DIR" ]] ; then
	mkdir -p "$ORIGINAL_MEDIA_DIR"
fi
if [[ ! -d "$ORIGINAL_MEDIA_DIR" ]] ; then
	echo "ERROR: failed to find or create ORIGINAL_MEDIA_DIR $ORIGINAL_MEDIA_DIR" >&2
	exit 2
fi

# MP3_URL: a randomly-selected (by the author), relatively-short mp3 file with free license
MP3_URL="http://freemusicarchive.org/music/download/e263a939f306c27e29cdbbd0a8b11a380b2d5628"
MP3_FILE="${ORIGINAL_MEDIA_DIR}/e263a939f306c27e29cdbbd0a8b11a380b2d5628"
if [[ ! -f "${MP3_FILE}" ]] ; then
	if ! pushd "$ORIGINAL_MEDIA_DIR" ; then
		echo "ERROR: failed to change directory to ORIGINAL_MEDIA_DIR $ORIGINAL_MEDIA_DIR" >&2
		exit 3
	fi
	wget http://freemusicarchive.org/music/download/"${MP3_FILE}"
	popd
fi

if [[ ! -f "${MP3_FILE}" ]] ; then
	echo "ERROR: failed to fetch mp3 test file $MP3_URL to local $MP3_FILE" >&2
	exit 4
fi

$BIN --frame-list \
| grep "^\ \ \*" \
| while read a b c ; do
	echo $b
  done \
| sed "s/\#.*//;/^[ \t]*$/d" \
| head -n 1000 \
| (
	num_tags=0
	num_passed=0
	num_failed=0
	test_result="passed"
	while read TAG ; do
		# handle special cases
		case $TAG in
		APIC)
			# TODO: better APIC test with image verify
			VAL="http://www.w3.org/Graphics/PNG/alphatest.png"
			[[ ! -f "alphatest" ]] && wget "$VAL"
			VAL="alphatest.png"
			;;
		PCNT)
			VAL="1234"
			;;
		RBUF)
			VAL="1024"
			;;
		TBPM)
			VAL="110"
			;;
		TPOS,TRCK)
			VAL="4/9"
			;;
		TRDA)
			VAL="$(date)"
			;;
		TSIZ)
			VAL="$(stat --format=%s "${MP3_FILE}")"
			;;
		TXXX)
			# TODO: insure that this is spec-compliant
			VAL="TEXT1:DESCRIPTION1"
			;;
		TSRC)
			# International Standard Recording Code [1]
			VAL="CC-XXX-YY-NNNNN"
			;;
		TYER)
			VAL="2014"
			;;
		*)
			VAL="VAL $TAG"
			;;
		esac
		if ./test_tag_write_verify.sh "$MP3_FILE" "$TAG" "$VAL" ; then
			num_passed=$(expr $num_passed + 1)
		else
			num_failed=$(expr $num_failed + 1)
			test_result="failed"
		fi
		# (( num_tags++ )) # bash iterator (tested)
		num_tags=$(expr $num_tags + 1) # busybox-safe iterator; both work in bash
		echo "" >&2 # for a little easier-to-read formatting
	done
	TRACE "Test Sequence complete: $num_passed tests passed, $num_failed tests failed, $num_tags total tags"
	if [[ "$test_result" == "passed" ]] ; then
		TRACE "END: ALL TESTS PASSED"
		exit 0
	else
		TRACE "END: AT LEAST 1 TEST FAILED"
		exit 1
	fi
)

exit $?

# References:

	# [1]
	# International Standard Recording Code
	# http://en.wikipedia.org/wiki/International_Standard_Recording_Code
