#!/bin/sh
# Copyright (C) 2026 Stefan Fambach (SteFam), https://www.fambach.net
# PolyForm Noncommercial 1.0.0, see LICENSE.md; commercial use only with his consent.
# Installs the ORGBRO X1 driver into CUPS and creates the queue. Run with sudo.
#   sudo ./install.sh 06:02:AC:C8:AF:65 [queue]
set -eu
ADDRESS="${1:?Bluetooth address of the X1, e.g. 06:02:AC:C8:AF:65}"
QUEUE="${2:-ORGBRO_X1}"
HERE="$(cd "$(dirname "$0")" && pwd)"
install -m 0755 "$HERE/rastertoorgbrox1" /usr/lib/cups/filter/rastertoorgbrox1
install -m 0755 "$HERE/orgbrox1" /usr/lib/cups/backend/orgbrox1
install -d /usr/share/cups/model/orgbro
install -m 0644 "$HERE/orgbro-x1.ppd" /usr/share/cups/model/orgbro/orgbro-x1.ppd
systemctl restart cups
lpadmin -p "$QUEUE" -E -v "orgbrox1://$ADDRESS" -P /usr/share/cups/model/orgbro/orgbro-x1.ppd \
    -D "ORGBRO X1" -o PageSize=w34h85 -o printer-error-policy=abort-job
echo "Queue $QUEUE ready: lp -d $QUEUE -o PageSize=w34h85 file.pdf"
