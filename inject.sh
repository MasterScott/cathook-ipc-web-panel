#!/usr/bin/env bash

pushd `dirname $0`

if ! [ $EUID == 0 ]; then
	echo "This script must be run as root"
	exit
fi

proc=$1

echo Attaching to "$proc"

# pBypass for crash dumps being sent
# You may also want to consider using -nobreakpad in your launch options.
sudo rm -rf /tmp/dumps # Remove if it exists
sudo mkdir /tmp/dumps # Make it as root
sudo chmod 000 /tmp/dumps # No permissions

# Get a Random name from the build_names file.
FILENAME=$(shuf -n 1 build_names)

# Create directory if it doesn't exist
if [ ! -d "/lib/i386-linux-gnu/" ]; then
  sudo mkdir /lib/i386-linux-gnu/
fi

# In case this file exists, get another one. ( checked it works )
while [ -f "/lib/i386-linux-gnu/${FILENAME}" ]; do
  FILENAME=$(shuf -n 1 build_names)
done

# echo $FILENAME > build_id # For detaching

sudo cp "/opt/cathook/bin/libcathook-textmode.so" "/lib/i386-linux-gnu/${FILENAME}"

echo loading "$FILENAME" to "$proc"

sudo gdb -n -q -batch \
  -ex "attach $proc" \
  -ex "set \$dlopen = (void*(*)(char*, int)) dlopen" \
  -ex "call \$dlopen(\"/lib/i386-linux-gnu/$FILENAME\", 1)" \
  -ex "call dlerror()" \
  -ex 'print (char *) $2' \
  -ex "catch syscall exit exit_group" \
  -ex "detach" \
  -ex "quit"

sudo rm "/lib/i386-linux-gnu/${FILENAME}"
