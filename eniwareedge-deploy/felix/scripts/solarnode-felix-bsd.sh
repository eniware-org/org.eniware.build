#!/bin/sh
### BEGIN INIT INFO
# Provides:          eniwareedge
# Required-Start:    $remote_fs
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: EniwareEdge daemon
# Description:       The EniwareEdge daemon is for collecting energy related
#                    data and uploading that to the central EniwareNet service,
#                    as well as intelligently responding to "smart grid"
#                    events such as load shedding.
### END INIT INFO
# 
# SysV init script for the EniwareEdge daemon for Apache Felix. Designed
# to be run as an /etc/init.d service by the root user.
#
# chkconfig: 3456 99 01
# description: Control the EniwareEdge Felix server
#
# Set JAVA_HOME to the path to your JDK or JRE.
# 
# Set ENIWAREEDGE_HOME to the directory that contains the following:
# 
# + <ENIWAREEDGE_HOME>/
# |
# +--+ felix/                     <-- Felix install dir
# |  |
# |  +--+ bin/
# |     |
# |     +-- felix.jar
# |
# +--+ conf/                      <-- configuration
# |  |
# |  +-- config.properties        <-- main Felix configuration
# |  +-- system.properties        <-- custom system properties
# |  +-- eniwareedge.xml
# |  +-- db.normal.properties     <-- normal DB properties
# |  +-- db.recover.properties    <-- recover DB properties
# |
# +--+ app/                      
#    |
#    +--+ boot/                   <-- OSGi bootstrap bundles
#    +--+ main/                   <-- EniwareEdge OSGi bundles
#
#
# Set PID_FILE to the path to the same path as specified in 
# eniwareedge.properties for the node.pidfile setting.
# 
# Set RUNAS to the name of the user to run the process as. The script
# will use "su" to run the node as this user, in the background.
# 
# Modify the APP_ARGS and JVM_ARGS variables as necessary.

JAVA_HOME=/usr/local
ENIWAREEDGE_HOME=/home/matt
VAR_DIR=${ENIWAREEDGE_HOME}/var
DB_DIR=${VAR_DIR}/db
LOG_DIR=${VAR_DIR}/log
DB_BAK_DIR=${VAR_DIR}/db-bak
FELIX_CACHE=${ENIWAREEDGE_HOME}/felix-cache
FELIX_HOME=${ENIWAREEDGE_HOME}/felix
PID_FILE=${ENIWAREEDGE_HOME}/var/eniwareedge-felix.pid
APP_ARGS="-Dfelix.config.properties=file:${ENIWAREEDGE_HOME}/conf/config.properties -Dfelix.system.properties=file:${ENIWAREEDGE_HOME}/conf/system.properties -Dsn.home=${ENIWAREEDGE_HOME}"
JVM_ARGS="-Xmx48m"
#JVM_ARGS="-Dcom.sun.management.jmxremote"
#JVM_ARGS="Xdebug -Xnoagent -Xrunjdwp:server=y,transport=dt_socket,address=9142,suspend=y"

RUNAS=

START_CMD="${JAVA_HOME}/bin/java ${JVM_ARGS} ${APP_ARGS} -jar ${FELIX_HOME}/bin/felix.jar ${FELIX_CACHE}"
START_SLEEP=3
STOP_TRIES=5

# function to create directory if doesn't already exist
setup_dir () {
	if [ ! -e $1 ]; then
		if [ -z "${RUNAS}" ]; then
			mkdir $1
		else
			su - $RUNAS -c "mkdir -p $1"
		fi
	fi
}

# function to stop process and wait for it to terminate
stop_proc () {
	pid=$1
	count=$2
	while let count-=1 && kill "$pid" 2>/dev/null; do
		sleep 1
	done
}

# function to start up process
do_start () {
	echo -n "Starting EniwareEdge server... "

	# Verify log dir exists; create if necessary
	setup_dir ${LOG_DIR}
	
	# Verify var dir exists; create if necessary
	setup_dir ${VAR_DIR}
	
	# Check to restore backup database
	if [ ! -e ${DB_DIR} -a -e ${DB_BAK_DIR} ]; then
		echo -n "restoring database... "
		cp -a ${DB_BAK_DIR} ${DB_DIR}
	fi
	
	if [ -z "${RUNAS}" ]; then
		${START_CMD} 1>${LOG_DIR}/stdout.log 2>&1 &
	else
		su - $RUNAS -c "${START_CMD} 1>${LOG_DIR}/stdout.log 2>&1 &"
	fi
	echo -n "sleeping for ${START_SLEEP} seconds to check PID... "
	sleep ${START_SLEEP}
	if [ -e $PID_FILE ]; then
		echo "Running as PID" `cat $PID_FILE`
	else
		echo "EniwareEdge does not appear to be running."
	fi
}

# function to stop process
do_stop () {
	pid=
	run=
	if [ -e $PID_FILE ]; then
		pid=`cat $PID_FILE`
		run=`ps -o pid= -p $pid`
	fi
	if [ -n "$run" ]; then
		echo -n "Stopping EniwareEdge $pid... "
		stop_proc $pid $STOP_TRIES
		run=`ps -o pid= -p $pid`
		
		# Backup DB to persistent storage
		if [ -z "$run" -a -e ${DB_DIR} ]; then
			echo -n "syncing database to backup dir... "
			setup_dir ${DB_BAK_DIR}
			rsync -am --delete ${DB_DIR}/* ${DB_BAK_DIR} 1>/dev/null 2>&1
		fi
		echo "done."
	else
		echo "EniwareEdge does not appear to be running."
	fi
}

# function to check status
do_status () {
	pid=
	run=
	if [ -e $PID_FILE ]; then
		pid=`cat $PID_FILE`
		run=`ps -o pid= -p $pid`
	fi
	if [ -n "$run" ]; then
		echo "EniwareEdge is running (PID $pid)"
	else
		echo "EniwareEdge does not appear to be running."
	fi
}

# Parse command line parameters.
case $1 in
	start)
		do_start
		;;

	status)
		do_status
		;;
	
	stop)
		do_stop
		;;

	*)
		# Print help
		echo "Usage: $0 {start|stop|status}" 1>&2
		exit 1
		;;
esac

exit 0


