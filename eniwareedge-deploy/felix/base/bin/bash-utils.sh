#!/bin/bash

sn-log-path() {
	echo /run/eniware/log/eniwareedge.log
}

sn-log-tail() {
	tail "$@" `sn-log-path`
}

sn-ctl() {
	sudo systemctl $1 eniwareedge
}

sn-stop() {
	sn-ctl stop
}

sn-start() {
	sn-ctl start
}

sn-restart() {
	sn-ctl restart
}

sn-status() {
	sn-ctl status
}

