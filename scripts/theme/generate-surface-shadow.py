#!/usr/bin/env python3
import argparse
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

SCALE = 8


def rounded_mask(size, box, radius):
    layer = Image.new("L", (size[0] * SCALE, size[1] * SCALE), 0)
    ImageDraw.Draw(layer).rounded_rectangle(
        [value * SCALE for value in (box[0], box[1], box[2] - 1, box[3] - 1)],
        radius=radius * SCALE,
        fill=255,
    )
    return layer.resize(size, Image.LANCZOS)


def build(extent, radius, offset, sigma, core):
    span = 2 * (extent + radius) + core
    size = (span, span)
    box = (extent, extent, span - extent, span - extent)
    shifted = (box[0], box[1] + offset, box[2], box[3] + offset)
    shadow = rounded_mask(size, shifted, radius).filter(ImageFilter.GaussianBlur(sigma))
    surface = rounded_mask(size, box, radius)
    alpha = ImageChops.multiply(shadow, ImageChops.invert(surface))
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    image.putalpha(alpha)
    return image


def main():
    parser = argparse.ArgumentParser(description="Generate the nine-slice surface shadow image.")
    parser.add_argument("output", type=Path)
    parser.add_argument("--extent", type=int, default=18)
    parser.add_argument("--radius", type=int, default=12)
    parser.add_argument("--offset", type=int, default=3)
    parser.add_argument("--sigma", type=float, default=5.5)
    parser.add_argument("--core", type=int, default=4)
    args = parser.parse_args()
    build(args.extent, args.radius, args.offset, args.sigma, args.core).save(args.output, optimize=True)


if __name__ == "__main__":
    main()
