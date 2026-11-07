# CUPS drivers

Small CUPS drivers for label printers that come without one for Linux. One folder per printer, each
with its filter, backend, PPD, install script, tests and README.

| Folder | Printer | Connection |
|---|---|---|
| [orgbro-x1](orgbro-x1/) | ORGBRO X1, 15 mm continuous tape | Bluetooth (RFCOMM) |
| [brother-ql810w](brother-ql810w/) | Brother QL-810W, 62 mm roll – setup only, uses Brother's driver | Network (dnssd/IPP) |

Python 3, standard library only. Tests: `python3 -m unittest discover <folder>`.

## License

Own code: PolyForm Noncommercial 1.0.0, see [LICENSE.md](LICENSE.md).
Commercial use only with the consent of Stefan Fambach (SteFam).

## Authors

- **Stefan Fambach** (SteFam) – idea and concept, review and testing – https://www.fambach.net
- **Claude** (Anthropic AI) – implementation, via Claude Code

## AI disclosure

This project is built with AI assistance. Stefan Fambach had the idea, wrote the concept and reviews and tests every change; the implementation (code and documentation) is written largely by Claude (Anthropic) via Claude Code.
