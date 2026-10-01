"""Lays a faint paper tooth over the rendered icons, writes them as sRGB PNGs and cuts the Mac icon's sizes."""

import sys
from pathlib import Path

import numpy as np
from PIL import Image

# The dark icon stays flat, like the app's dark paper.
STRENGTH = {"AppIcon": 3.2, "AppIcon-Dark": 0.0, "AppIcon-Tinted": 0.0, "AppIcon-Mac-1024": 3.2}
# The rest of the sizes macOS asks for, cut from the 1024-pixel Mac icon.
MAC_SIZES = (16, 32, 64, 128, 256, 512)


def grain(size: int, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    tooth = rng.normal(0, 1, (size, size))
    # Soft, uneven pulp: coarse noise blown up and smoothed.
    coarse = Image.fromarray(((rng.normal(0, 1, (size // 16, size // 16)) + 4) * 32).clip(0, 255).astype(np.uint8))
    pulp = np.asarray(coarse.resize((size, size), Image.BICUBIC), dtype=np.float32) / 32 - 4
    return tooth * 0.8 + pulp * 0.35


def main(folder: Path) -> None:
    for variant, strength in STRENGTH.items():
        path = folder / f"{variant}.png"
        image = Image.open(path)
        # iOS icons are opaque; the Mac one keeps the clear margin around its rounded square.
        pixels = np.asarray(image.convert("RGBA" if "Mac" in variant else "RGB"), dtype=np.float32)
        if strength:
            tooth = grain(image.width, seed=17) * strength
            if pixels.shape[2] == 4:
                tooth *= pixels[..., 3] / 255
            pixels[..., :3] += tooth[..., None]
        Image.fromarray(pixels.clip(0, 255).astype(np.uint8)).save(path, optimize=True)
        print(f"grained {path.name}")

    # Scaled with premultiplied alpha, so the clear margin doesn't bleed dark into the edge.
    mac = Image.open(folder / "AppIcon-Mac-1024.png").convert("RGBa")
    for size in MAC_SIZES:
        path = folder / f"AppIcon-Mac-{size}.png"
        mac.resize((size, size), Image.LANCZOS).convert("RGBA").save(path, optimize=True)
        print(f"wrote {path.name}")


if __name__ == "__main__":
    main(Path(sys.argv[1]))
