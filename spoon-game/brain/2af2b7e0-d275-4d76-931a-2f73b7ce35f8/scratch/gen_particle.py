import zlib
import struct

def generate_particle_png(filename):
    w, h = 64, 64
    # Create a radial gradient (greyish sparkle)
    data = bytearray()
    for y in range(h):
        # PNG scanline filter byte
        data.append(0)
        for x in range(w):
            dx = x - 32
            dy = y - 32
            dist = (dx*dx + dy*dy)**0.5
            # Alpha based on distance from center
            alpha = int(255 * max(0, 1 - (dist / 32.0))**2)
            # RGB is greyish
            data.extend(struct.pack('BBBB', 220, 220, 220, alpha))

    def make_chunk(typ, data):
        return struct.pack('>I', len(data)) + typ + data + struct.pack('>I', zlib.crc32(typ + data) & 0xffffffff)

    png_header = b'\x89PNG\r\n\x1a\n'
    ihdr = make_chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
    idat = make_chunk(b'IDAT', zlib.compress(data))
    iend = make_chunk(b'IEND', b'')

    with open(filename, 'wb') as f:
        f.write(png_header + ihdr + idat + iend)

if __name__ == "__main__":
    generate_particle_png("assets/particle.png")
