#!/bin/bash
set -eou pipefail

ARCH="$1"

echo "bikeos" > "${ROOT?}/etc/hostname"
# '..vpJrbBlNzG6' is crypt.crypt('bicycle', '..')
sed -i 's,root:[^:]*,root:..vpJrbBlNzG6,' "${ROOT?}/etc/shadow"

# filesystems
mkdir -p "${ROOT?}/media/sdcard"
install -m 644 -o root -g root /spec/fstab "${ROOT?}/etc/fstab"

# audio
install -m 644 -o root -g root /bikeos/etc/asound.conf "${ROOT?}/etc/asound.conf"
install -D -m 444 -o root -g root /bikeos/usr/share/bikeos/boot.mp3 "${ROOT?}/usr/share/bikeos/boot.mp3"

# daemon
install -m 755 -o root -g root /bikeos/bin/bosd-"$ARCH" "${ROOT?}/usr/sbin/bosd"
install -m 644 -o root -g root /bikeos/bosd.service "${ROOT?}/etc/systemd/system"
install -m 644 -o root -g root /bikeos/etc/apparmor.d/local/usr.sbin.tcpdump "${ROOT?}/etc/apparmor.d/local/usr.sbin.tcpdump"

# alert bosd on wlan changes
install -m 644 -o root -g root /bikeos/95-wlan.rules "${ROOT?}/etc/udev/rules.d"

# time stuff
install -m 644 -o root -g root /bikeos/gps-time.service "${ROOT?}/etc/systemd/system"
mkdir -p "${ROOT?}/var/lib/systemd/timesync"
touch "${ROOT?}/var/lib/systemd/timesync/clock"
chown root:root "${ROOT?}/var/lib/systemd/timesync/clock"
