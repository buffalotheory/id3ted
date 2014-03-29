#!/bin/bash
# Bryant Hansen

# Description:
# test script which writes the TBPM tag to a file, reads it back and verifies

ME="$(basename "$0")"

BIN=./id3ted
TEST_FILE_ORIG=""
TEST_DIR="."

[[ test.conf ]] && [[ -f test.conf ]] && . test.conf

# assume passed unless some stage fails
test_result="passed"

function TRACE() {
	echo -e "$(date "+%Y%m%d_%H%M%S") ${ME}: $1" >&2
}

TRACE "$(date): executing test to verify read/write of id3 BPM field"

[[ "$1" ]] && TEST_FILE_ORIG="$1"
if [[ ! "$TEST_FILE_ORIG" ]] ; then
	TRACE "ERROR: test audio file must be specified.  Exiting abnormally."
	exit 2
fi

file_under_test="$TEST_DIR"/"$(basename "$TEST_FILE_ORIG")"

TRACE "copying source testfile $TEST_FILE_ORIG to working file $file_under_test"
cp -a "$TEST_FILE_ORIG" "$file_under_test"

if $BIN -l "$file_under_test" | grep "> [ \t]*TBPM:" > /dev/null ; then
	TRACE "TBPM already found in source audio file.  test failed."
	test_result="failed"
fi

tags_before="$($BIN -l "$file_under_test")"

TRACE "writing TBPM to $file_under_test"
$BIN --TBPM "120.11" "$file_under_test"

tags_after="$($BIN -l "$file_under_test")"

res="$(diff <(echo -e "$tags_before") <(echo -e "$tags_after"))"

TRACE "file modifications to ${file_under_test}:"
echo -e "$res"
if ! echo "$res" | grep "> [ \t]*TBPM:" > /dev/null ; then
	TRACE "TBPM tag not added to file.  test failed."
	test_result="failed"
fi
if [[ "$test_result" == "passed" ]] ; then
	TRACE "test passed"
else
	exit 1
fi

exit 0

