#!/bin/bash

# sha1sum $^ | awk ' { print $$1; } ' >volumes/opentracker/whitelist.txt
btshowmetainfo /vols/*/*.gz.torrent | grep 'info hash' | sed 's/ //g' | cut -f2 -d: >/tmp/whitelist.txt
opentracker -f /etc/opentracker/opentracker.conf
