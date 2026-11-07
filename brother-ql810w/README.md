# Brother QL-810W – our setup

This folder holds no Brother files. The driver itself (PPD, filters, paper tool) is Brother's
proprietary package **ql810wpdrv**; download it from Brother's support site:
https://support.brother.com → QL-810W → Downloads → Linux → "Printer driver (deb package)".

`setup.sh` builds our queue on top of it:

```sh
sudo ./setup.sh                 # queue QL-810W_take, network printer via dnssd
sudo ./setup.sh --dry-run       # only show what would be done
sudo ./setup.sh MyQueue 'dnssd://Brother%20QL-810W._ipp._tcp.local/?uuid=…'
```

It

1. creates the queue with Brother's PPD (`lpadmin`, default size 62x100),
2. adds our own label sizes with Brother's paper tool `brpapertoollpr_ql810w`:
   62x30, 62x50, 62x62, 62x120 (width × height in mm, on the 62 mm roll),
3. shortens the size list to what fits the 62 mm roll: **62x100**, **62X1** (62 mm continuous) and
   the own sizes. The full PPD is kept as `/etc/cups/ppd/<queue>.ppd.orig`,
4. restarts CUPS and prints the CUPS names of the own sizes.

## CUPS names of the own sizes

Brother's paper tool gives every own size an internal name (`BrL…`); the readable name stands only
after the slash in the PPD (`*PageSize BrL053E03E8E83B/62x62`). `lpoptions -l` shows the internal
name, print dialogs show the readable one. Do not rename them: the name is also stored in Brother's
files under `/opt/brother/PTouch/ql810w/inf/`.

On Earth (set up 2026-11) the names are:

| Size | CUPS PageSize |
|---|---|
| 62x30 | BrL053E01E3D0F6 |
| 62x50 | BrL053E03262D56 |
| 62x62 | BrL053E03E8E83B |
| 62x120 | BrL063E078EB482 |

**Warning:** the names can change when a size is created again (new setup, driver update, other
machine). After `setup.sh` take the names it prints, or look them up:

```sh
curl -s http://localhost:631/printers/QL-810W_take.ppd | grep '^\*PageSize BrL'
```

## Options

- Turn a label (landscape layout on the 62 mm roll): `-o orientation-requested=4`
- Example: `lp -d QL-810W_take -o PageSize=BrL053E01E3D0F6 -o orientation-requested=4 label.pdf`

## Taxmod formats

The Taxmod print service (`config.json` → `formats`, or the printer in the model, "62x30=BrL…")
uses:

| Format | PageSize | Options |
|---|---|---|
| holder62 (62x50) | BrL053E03262D56 | orientation-requested=4 |
| material62 (62x30) | BrL053E01E3D0F6 | orientation-requested=4 |
| 62x62 | BrL053E03E8E83B | – |

A Brother driver update may rewrite the PPD; run `setup.sh` again afterwards.
