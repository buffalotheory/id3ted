#!/bin/bash
# Bryant Hansen

# Description:
# test script which writes the TBPM tag to a file, reads it back and verifies

# local script info
ME="$(basename "$0")"
USAGE="${ME}  [  file  [  tag  [  value  ]  ]  ]"

# defaults
BIN=./id3ted
TEST_FILE_ORIG=""
TEST_DIR="."
TAG="TBPM"
VAL="120"

# import (source) config settings
[[ test.conf ]] && [[ -f test.conf ]] && . test.conf

# assume passed unless some stage fails
test_result="passed"

# functions
function TRACE() {
	echo -e "$(date "+%Y%m%d_%H%M%S") ${ME}: $1" >&2
}

# handle args
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] ; then
	echo -e "USAGE: \n   $USAGE"
	exit 0
fi
[[ "$1" ]] && TEST_FILE_ORIG="$1"
[[ "$2" ]] && TAG="$2"
[[ "$3" ]] && VAL="$3"

if [[ ! "$TEST_FILE_ORIG" ]] ; then
	TRACE "ERROR: test audio file must be specified.  Exiting abnormally."
	exit 2
fi

# allow tag to be specified as the full FID3_???? name, as used in the sources
TAG="${TAG#FID3_}"

# the actual test file will be a copy of the original, located within TEST_DIR
file_under_test="$TEST_DIR"/"$(basename "$TEST_FILE_ORIG")"


# something like main
TRACE "START TEST: executing id3 frame read/write test (params: BIN=${BIN}  TEST_FILE=${TEST_FILE_ORIG}  TAG=${TAG}  VAL=${VAL})"

TRACE "copying source testfile $TEST_FILE_ORIG to working file $file_under_test"
TRACE "cp -a '$TEST_FILE_ORIG' '$file_under_test'"
cp -a "$TEST_FILE_ORIG" "$file_under_test"

if $BIN -l "$file_under_test" | grep "> [ \t]*${TAG}:" > /dev/null ; then
	TRACE "${TAG} already found in source audio file.  test failed."
	test_result="failed"
fi

tags_before="$($BIN -l "$file_under_test")"

TRACE "writing ${TAG} with value '${VAL}' to $file_under_test"
TRACE "$BIN --$TAG '$VAL' '$file_under_test'"
$BIN --$TAG "$VAL" "$file_under_test"

tags_after="$($BIN -l "$file_under_test")"

MIN_TAG_LEN=3
if [[ "${#tags_after}" -lt $MIN_TAG_LEN ]] ; then
	TRACE "TEST FAILED: could not read tags from test file $file_under_test"
	test_result="failed"
fi

res="$(diff <(echo -e "$tags_before") <(echo -e "$tags_after"))"

TRACE "changes to file_under_test ${file_under_test} (${#res} character diff):"
echo -e "$res" | sed "s/^/\ \ \ /"

# need tag-specific result handling
case $TAG in
	APIC)
		SUCCESS_REGEX="> APIC: image/"
		TRACE "$TAG TAG REGEX: $SUCCESS_REGEX"
		;;

	COMM)
		res="${res/\[\]\(XXX\): /}"
		# COMM: [](XXX): VAL COMM
		TRACE "$TAG TAG: filtered diff"
		;;
	WXXX)
		res="${res/\[\]: /}"
		TRACE "$TAG TAG: filtered diff"
		;;
	USLT)
		# solving this one with a massive bit of cat-on-the-keyboard sed ugliness
		res="$(echo "$res" | sed -e 's/[ \t$]*>[ \t^]*//g;' -e :a -e '/):$/N; s/\[\](XXX):[ \t]*\n//; ta')"
		TRACE "reformatted diff:"
		echo -e "$res" | sed "s/^/\ \ \ /" >&2
		;;
	*)
		SUCCESS_REGEX="> [ \t]*${TAG}:[ \t]*${VAL}"
		;;
esac

if ! echo "$res" | grep "$SUCCESS_REGEX" > /dev/null ; then
	if [[ "${#res}" == "0" ]] ; then
		TRACE "${TAG} tag not added to file; file unchanged.  test failed."
	else
		TRACE "${TAG} tag not added to file.  test failed."
	fi
	test_result="failed"
fi

if [[ "$test_result" == "passed" ]] ; then
	TRACE "## END: TEST PASSED ##"
    exit 0
else
	TRACE "## END: TEST FAILED ##  params: BIN=${BIN}  TEST_FILE=${TEST_FILE_ORIG}  TAG=${TAG}  VAL=${VAL}"
	exit 1
fi

