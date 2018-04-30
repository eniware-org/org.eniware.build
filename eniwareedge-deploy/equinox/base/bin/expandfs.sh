#!/usr/bin/env bash

if [ ! `id -u` = 0 ]; then
	echo "You must be root to run this script."
	exit 3
fi

DRYRUN=0
VERBOSE=0
OLD_GEOM_FILE=/var/local/eniwareedge-expandfs.saved

while getopts ":no:v" opt; do
	case $opt in
		n) DRYRUN=1 ;;
		o) OLD_GEOM_FILE=$OPTARG ;;
		v) VERBOSE=1 ;;
	esac
done

shift $(($OPTIND - 1))

ENIWARENODE_PART=`lsblk -npo kname,label |grep -i ENIWARENODE |cut -d' ' -f 1`

if [ -z "$ENIWARENODE_PART" ]; then
	echo "Error: ENIWARENODE partition not discovered"
	exit 1
elif [ $VERBOSE = 1 ]; then
	echo "Discovered ENIWARENODE partition ${ENIWARENODE_PART}..."
fi

# get the device and partition number with the ENIWARENODE label
ENIWARENODE_DEV=
ENIWARENODE_PART_NUM=
MMC_REGEX='(.*[0-9]+)p([0-9]+)'
SD_REGEX='(.*)([0-9]+)'
if [[ $ENIWARENODE_PART =~ $MMC_REGEX ]]; then
	ENIWARENODE_DEV=${BASH_REMATCH[1]}
	ENIWARENODE_PART_NUM=${BASH_REMATCH[2]}
elif [[ $ENIWARENODE_PART =~ $SD_REGEX ]]; then
	ENIWARENODE_DEV=${BASH_REMATCH[1]}
	ENIWARENODE_PART_NUM=${BASH_REMATCH[2]}
fi
if [ -z "$ENIWARENODE_DEV" ]; then
	echo "Error: ENIWARENODE device not discovered"
	exit 1
fi
if [ -z "$ENIWARENODE_PART_NUM" ]; then
	echo "Error: ENIWARENODE partition number not discovered"
	exit 1
fi

if [ $VERBOSE = 1 ]; then
	echo "Expanding ${ENIWARENODE_DEV} partition ${ENIWARENODE_PART_NUM}"
	echo "Saving recovery output to ${OLD_GEOM_FILE}..."
fi
if [ $DRYRUN = 1 ]; then
	echo ',+' |sfdisk ${ENIWARENODE_DEV} -N${ENIWARENODE_PART_NUM} --no-reread \
		-f -uS -q -n 2>/dev/null
else
	echo ',+' |sfdisk ${ENIWARENODE_DEV} -N${ENIWARENODE_PART_NUM} --no-reread \
		-f -uS -q -O "${OLD_GEOM_FILE}" 2>/dev/null
fi

# Inform the kernel of the partition change
if [ $VERBOSE = 1 ]; then
	echo -e "\nReloading partition table for ${ENIWARENODE_DEV}..."
fi
if [ $DRYRUN = 1 ]; then
	echo "partx -u ${ENIWARENODE_DEV}"
else
	partx -u ${ENIWARENODE_DEV}
fi

# Resize the filesystem to use the entire partition
if [ $VERBOSE = 1 ]; then
	echo -e "\nExpanding filesystem on partition ${ENIWARENODE_PART}..."
fi
if [ $DRYRUN = 1 ]; then
	echo "resize2fs ${ENIWARENODE_PART}"
else
	resize2fs "${ENIWARENODE_PART}"
fi
