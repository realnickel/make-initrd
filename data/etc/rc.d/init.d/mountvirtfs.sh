#!/bin/sh
### BEGIN INIT INFO
# Provides:            mountvirtfs
# Required-Start:
# Should-Start:
# Required-Stop:
# Should-Stop:
# Default-Start:       3 4 5
# Default-Stop:
# Short-Description:   Mounts /sys and /proc virtual (kernel) filesystems.
#                      Mounts /run (tmpfs) and /dev (devtmpfs).
# Description:         Mounts /sys and /proc virtual (kernel) filesystems.
#                      Mounts /run (tmpfs) and /dev (devtmpfs).
### END INIT INFO

. /etc/init.d/template

makenod() {
	[ -e /dev/$1 ] || mknod /dev/$1 $2 $3 $4
}

start() {
	if ! mount -n -t devtmpfs -o mode=755,size=5m udevfs /dev 2>/dev/null; then
		mount -n -t tmpfs -o mode=755,size=5m udevfs /dev
	fi

	makenod ram     b 1 1
	makenod null    c 1 3
	makenod zero    c 1 5
	makenod full    c 1 7
	makenod random  c 1 8
	makenod kmsg    c 1 11
	makenod systty  c 4 0
	makenod tty0    c 4 0
	makenod tty1    c 4 1
	makenod tty     c 5 0
	makenod console c 5 1
	makenod ptmx    c 5 2

	mount -n -t sysfs -o nodev,noexec,nosuid none  /sys
	mount -n -t proc  -o nodev,noexec,nosuid none  /proc
	mount -n -t tmpfs -o mode=755,size=5m    runfs /run

	mkdir -p /dev/pts /dev/shm /run/lock/subsys /run/user /run/udev /run/systemd

	:> /run/utmp
	chmod 0664 /run/utmp

	mkdir -p /
}

stop() {
	. /.initrd/initenv

	local mp
	# Move filesystems to real root
	for mp in dev run ${EXPORT_FS-}; do
		if [ -d "$rootmnt/$mp" ]; then
			mount --move ${DEBUG:+-v} "/$mp" "$rootmnt/$mp"
		else
			umount ${DEBUG:+-v} "/$mp"
		fi
	done
}

switch "${1-}"