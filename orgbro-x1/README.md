# CUPS driver for the ORGBRO X1

The ORGBRO X1 is a small Bluetooth label printer for 15 mm continuous tape (head 12 mm, 96 dots,
203 dpi). There is no driver for Linux; this one makes it an ordinary CUPS queue
([D-1216](../../docs/NewConcept/90-decision-log.md)). Python 3, standard library only.

```mermaid
flowchart LR
  P["PDF, lp -d ORGBRO_X1"] --> R["CUPS: pdftoraster"]
  R --> F["rastertoorgbrox1: raster → X1 frames"]
  F --> B["orgbrox1 backend"]
  B -- "Bluetooth RFCOMM channel 1" --> X["ORGBRO X1"]
```

| File | What it is |
|---|---|
| `rastertoorgbrox1` | CUPS filter: 1-bit raster in, X1 frames out |
| `orgbrox1` | CUPS backend: `orgbrox1://<address>[/<channel>]`, opens RFCOMM itself |
| `orgbro-x1.ppd` | sizes 12×20 … 12×100 mm plus custom sizes, darkness 5 / 9 / 13 |
| `install.sh` | copies the three into CUPS and creates the queue |

## Protocol

Read from the vendor's app XeasyLabel, whose SDK calls the X1 «HP2». Every frame is
`64 cmd seq lenLo lenHi data… crc(4) 9B`; the app sends the checksum as zero and the printer takes it.

| cmd | data | meaning |
|---|---|---|
| `0A` | 1 byte | speed, the app sends 25 |
| `09` | 1 byte | darkness 5 / 9 / 13 |
| `04` | `18 00` | start of the job (first label only) |
| `00` | 24 × 12 bytes | 24 rows of 96 dots, MSB first, 1 = black; the app moves the picture one dot along |
| `02` | `48 00` / `18 00` | feed 72 dots after each label, 24 more after the last |

The printer answers with frames of command `FF` (status). The filter's output for a test picture is
byte for byte what the app sent, and that job printed.

## Set up (Linux Mint)

1. Pair the X1 once (Bluetooth settings). Close its serial connection in the desktop afterwards,
   or that connection holds the channel.
2. `sudo ./install.sh 06:02:AC:C8:AF:65` — the address from `bluetoothctl devices`.
3. Test: `lp -d ORGBRO_X1 -o PageSize=w34h85 file.pdf` (12×30 mm). Other sizes:
   `lpoptions -p ORGBRO_X1 -l`.
4. In the model, the printer gets the queue `ORGBRO_X1`; the print service then sends to it like to
   any other queue.

## Test

`python3 -m unittest discover tools/cups-orgbro-x1`
