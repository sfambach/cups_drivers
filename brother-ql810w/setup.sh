#!/bin/sh
# Copyright (C) 2026 Stefan Fambach (SteFam), https://www.fambach.net
# PolyForm Noncommercial 1.0.0, see LICENSE.md; commercial use only with his consent.
# Sets up a Brother QL-810W queue with our label sizes on top of Brother's own driver
# (package ql810wpdrv, not included here). Run with sudo.
#   sudo ./setup.sh [--dry-run] [queue] [device-uri]
set -eu

DRY=""
if [ "${1:-}" = "--dry-run" ]; then DRY=1; shift; fi
QUEUE="${1:-QL-810W_take}"
URI="${2:-dnssd://Brother%20QL-810W._ipp._tcp.local/?uuid=e3248000-80ce-11db-8000-f889d23024bc}"

BROTHER=/opt/brother/PTouch/ql810w
PPD_SRC="$BROTHER/cupswrapper/brother_ql810w_printer_en.ppd"
case "$(uname -m)" in x86_64|amd64) ARCH=x86_64 ;; *) ARCH=i686 ;; esac
PAPERTOOL="$BROTHER/lpd/$ARCH/brpapertoollpr_ql810w"
PPD="/etc/cups/ppd/$QUEUE.ppd"

# Own sizes (width x height in mm) added with Brother's paper tool.
CUSTOM="62x20 62x30 62x50 62x62 62x120"
# Brother's built-in sizes we keep; all others are removed from the queue's PPD.
KEEP_BUILTIN="62x100 62X1"

run() {
    if [ -n "$DRY" ]; then echo "+ $*"; else "$@"; fi
}

if [ -z "$DRY" ]; then
    [ "$(id -u)" -eq 0 ] || { echo "Run with sudo (or use --dry-run)." >&2; exit 1; }
    [ -f "$PPD_SRC" ] || { echo "Brother driver missing: install ql810wpdrv first (see README)." >&2; exit 1; }
fi

run lpadmin -p "$QUEUE" -E -v "$URI" -P "$PPD_SRC" -D "Brother QL-810W" -o PageSize=62x100

for size in $CUSTOM; do
    w="${size%x*}"; h="${size#*x}"
    run "$PAPERTOOL" -P "$QUEUE" -n "$size" -w "$w" -h "$h"
done

# Shorten the size list: keep the built-in sizes above and every Brother custom size (BrL...).
keep_re="BrL[0-9A-F]*"
for s in $KEEP_BUILTIN; do keep_re="$keep_re|$s"; done
if [ -n "$DRY" ]; then
    echo "+ remove PageSize/PageRegion/ImageableArea/PaperDimension entries not matching ($keep_re) from $PPD"
else
    cp "$PPD" "$PPD.orig"
    awk -v keep="^($keep_re)(/|:)" '
        /^\*(PageSize|PageRegion|ImageableArea|PaperDimension) / {
            name = $2; if (name !~ keep) next
        }
        /^\*Default(PageSize|PageRegion|ImageableArea|PaperDimension):/ { sub(/:.*/, ": 62x100") }
        { print }' "$PPD.orig" > "$PPD"
    systemctl restart cups
fi

echo
echo "CUPS names of the sizes (use these in Taxmod, e.g. 62x30=BrL...):"
if [ -n "$DRY" ]; then
    echo "+ grep '^\*PageSize BrL' $PPD"
else
    grep '^\*PageSize BrL' "$PPD" | sed -E 's/^\*PageSize (BrL[0-9A-F]+)\/([^:]+):.*/  \2 = \1/'
fi
