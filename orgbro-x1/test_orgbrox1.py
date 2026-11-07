"""Guards the X1 filter: its output for a known raster must stay byte for byte what the vendor's app sends."""
import hashlib
import importlib.machinery
import importlib.util
import io
import os
import struct
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))


def load(name):
    loader = importlib.machinery.SourceFileLoader(name, os.path.join(HERE, name))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


FILTER = load('rastertoorgbrox1')
BACKEND = load('orgbrox1')


def raster(width, height, pages=1):
    """A 1-bit black-is-1 raster: frame of 3 dots and a diagonal, as in the first print on the X1."""
    line_bytes = (width + 7) // 8
    out = b'3SaR'
    for _ in range(pages):
        header = bytearray(1796)
        struct.pack_into('<II', header, 372, width, height)
        struct.pack_into('<IIIII', header, 384, 1, 1, line_bytes, 0, 3)
        out += bytes(header)
        for y in range(height):
            row = bytearray(line_bytes)
            for x in range(width):
                if x < 3 or x >= width - 3 or y < 3 or y >= height - 3 or abs(x * height // width - y) < 3:
                    row[x >> 3] |= 0x80 >> (x & 7)
            out += bytes(row)
    return out


def frames(data):
    out, index = [], 0
    while index < len(data):
        assert data[index] == 0x64 and data[index + 5 + (data[index + 3] | data[index + 4] << 8) + 4] == 0x9B
        length = data[index + 3] | data[index + 4] << 8
        out.append((data[index + 1], data[index + 2], data[index + 5:index + 5 + length]))
        index += 10 + length
    return out


class FilterTest(unittest.TestCase):
    def test_matches_vendor_app(self):
        data = FILTER.encode(io.BytesIO(raster(96, 240)), 9)
        # sha256 of the job the vendor SDK built for the same picture, printed fine on 2026-11-07
        self.assertEqual(hashlib.sha256(data).hexdigest(),
                         '7ac8c8d3ab7c4602e0a1282a9a5377c433f575fcb8e63539f96ddb4186cd7b7e')

    def test_two_pages_start_once_and_end_once(self):
        commands = [command for command, _seq, _data in frames(FILTER.encode(io.BytesIO(raster(96, 48, 2)), 13))]
        self.assertEqual(commands.count(0x04), 1)
        self.assertEqual(commands[-2:], [0x02, 0x02])
        self.assertEqual(commands.count(0x02), 3)

    def test_narrow_page_is_centred(self):
        rows = [data for command, _seq, data in frames(FILTER.encode(io.BytesIO(raster(80, 24)), 9)) if command == 0]
        self.assertEqual(rows[0][:12], bytes([0x00, 0x7F]) + b'\xff' * 9 + bytes([0x80]))

    def test_density_option(self):
        self.assertEqual(FILTER.density_from('PageSize=w34h85 X1Density=13'), 13)
        self.assertEqual(FILTER.density_from('X1Density=7'), 9)

    def test_backend_uri(self):
        self.assertEqual(BACKEND.parse('orgbrox1://06:02:ac:c8:af:65'), ('06:02:AC:C8:AF:65', 1))
        self.assertEqual(BACKEND.parse('orgbrox1://06:02:AC:C8:AF:65/3'), ('06:02:AC:C8:AF:65', 3))
        with self.assertRaises(ValueError):
            BACKEND.parse('serial:/dev/rfcomm0')


if __name__ == '__main__':
    unittest.main()
