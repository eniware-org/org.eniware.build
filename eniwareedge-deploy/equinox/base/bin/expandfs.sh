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

ENIWAREEdge_PART=`lsblk -npo kname,label |grep -i ENIWAREEdge |cut -d' ' -f 1`

if [ -z "$ENIWAREEdge_PART" ]; then
	echo "Error: ENIWAREEdge partition not discovered"
	exit 1
elif [ $VERBOSE = 1 ]; then
	echo "Discovered ENIWAREEdge partition ${ENIWAREEdge_PART}..."
fi

# get the device and partition number with the ENIWAREEdge label
ENIWAREEdge_DEV=
ENIWAREEdge_PART_NUM=
MMC_REGEX='(.*[0-9]+)p([0-9]+)'
SD_REGEX='(.*)([0-9]+)'
if [[ $ENIWAREEdge_PART =~ $MMC_REGEX ]]; then
	ENIWAREEdge_DEV=${BASH_REMATCH[1]}
	ENIWAREEdge_PART_NUM=${BASH_REMATCH[2]}
elif [[ $ENIWAREEdge_PART =~ $SD_REGEX ]]; then
	ENIWAREEdge_DEV=${BASH_REMATCH[1]}
	ENIWAREEdge_PART_NUM=${BASH_REMATCH[2]}
fi
if [ -z "$ENIWAREEdge_DEV" ]; then
	echo "Error: ENIWAREEdge device not discovered"
	exit 1
fi
if [ -z "$ENIWAREEdge_PART_NUM" ]; then
	echo "Error: ENIWAREEdge partition number not discovered"
	exit 1
fi

if [ $VERBOSE = 1 ]; then
	echo "Expanding ${ENIWAREEdge_DEV} partition ${ENIWAREEdge_PART_NUM}"
	echo "Saving recovery output to ${OLD_GEOM_FILE}..."
fi
if [ $DRYRUN = 1 ]; then
	echo ',+' |sfdisk ${ENIWAREEdge_DEV} -N${ENIWAREEdge_PART_NUM} --no-reread \
		-f -uS -q -n 2>/dev/null
else
	echo ',+' |sfdisk ${ENIWAREEdge_DEV} -N${ENIWAREEdge_PART_NUM} --no-reread \
		-f -uS -q -O "${OLD_GEOM_FILE}" 2>/dev/null
fi

# Inform the kernel of the partition change
if [ $VERBOSE = 1 ]; then
	echo -e "\nReloading partition table for ${ENIWAREEdge_DEV}..."
fi
if [ $DRYRUN = 1 ]; then
	echo "partx -u ${ENIWAREEdge_DEV}"
else
	partx -u ${ENIWAREEdge_DEV}
fi

# Resize the filesystem to use the entire partition
if [ $VERBOSE = 1 ]; then
	echo -e "\nExpanding filesystem on partition ${ENIWAREEdge_PART}..."
fi
if [ $DRYRUN = 1 ]; then
	echo "resize2fs ${ENIWAREEdge_PART}"
else
	resize2fs "${ENIWAREEdge_PART}"
fi
