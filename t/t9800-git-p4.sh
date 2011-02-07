#!/bin/sh

test_description='git-p4 tests'

. ./test-lib.sh

p4 -h >/dev/null 2>&1
retc=$?
p4d -h >/dev/null 2>&1
retd=$?
if test $retc -ne 0 -o $retd -ne 0
then
	skip_all='skipping git-p4 tests; no p4 or p4d'
	test_done
fi

GITP4=$GIT_BUILD_DIR/contrib/fast-import/git-p4
P4DPORT=10669

db="$TRASH_DIRECTORY/db"
cli="$TRASH_DIRECTORY/cli"
git="$TRASH_DIRECTORY/git"

test_debug 'echo p4d -q -d -r "$db" -p $P4DPORT'
test_expect_success setup '
	mkdir -p "$db" &&
	p4d -q -d -r "$db" -p $P4DPORT &&
	# wait for it to finish its initialization
	sleep 1 &&
	mkdir -p "$cli" &&
	mkdir -p "$git" &&
	export P4PORT=localhost:$P4DPORT
'

test_expect_success 'add p4 files' '
	cd "$cli" &&
	p4 client -i <<-EOF &&
	Client: client
	Description: client
	Root: $cli
	View: //depot/... //client/...
	EOF
	export P4CLIENT=client &&
	echo file1 >file1 &&
	p4 add file1 &&
	p4 submit -d "file1" &&
	cd "$TRASH_DIRECTORY"
'

test_expect_success 'basic git-p4 clone' '
	"$GITP4" clone --dest="$git" //depot &&
	rm -rf "$git" && mkdir "$git"
'

test_expect_success 'shutdown' '
	pid=`pgrep -f p4d` &&
	test -n "$pid" &&
	test_debug "ps wl `echo $pid`" &&
	kill $pid
'

test_done
