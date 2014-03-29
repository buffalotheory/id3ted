#!/bin/bash
# Bryant Hansen

ME="$(basename "$0")"

bin=./id3ted
test_file_orig="/data/media/mp3/Vast/here.mp3"

# assume passed unless some stage fails
test_result="passed"

test_dir="."

function TRACE() {
	echo -e "${ME}: $1" >&2
}

TRACE "$(date): executing test to verify read/write of id3 BPM field"

[[ "$1" ]] && test_file_orig="$1"
file_under_test="$test_dir"/"$(basename "$test_file_orig")"

if $bin -l "$file_under_test" | grep "> [ \t]*TBPM:" > /dev/null ; then
	TRACE "TBPM already found in source audio file.  test failed."
	test_result="failed"
fi

TRACE "copying source testfile $test_file_orig to working file $file_under_test"
cp -a "$test_file_orig" "$file_under_test"

tags_before="$($bin -l "$file_under_test")"

TRACE "writing TBPM to $file_under_test"
$bin --TBPM "120.11" "$file_under_test"

tags_after="$($bin -l "$file_under_test")"

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

