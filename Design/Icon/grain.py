"""Writes the grained paper the flower lies on in the light icon, and tidies the flower layers.

usage: grain.py <Icon Composer assets directory>
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image

# The paper of the light icon, as in the app, and how much tooth it has. The dark icon stays flat,
# like the app's dark paper, so Icon Composer fills it with plain #101012.
PAPER = (245, 241, 232)
STRENGTH = 3.2
SIZE = 1024


def grain(size: int, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    tooth = rng.normal(0, 1, (size, size))
    # Soft, uneven pulp: coarse noise blown up and smoothed.
    coarse = Image.fromarray(((rng.normal(0, 1, (size // 16, size // 16)) + 4) * 32).clip(0, 255).astype(np.uint8))
    pulp = np.asarray(coarse.resize((size, size), Image.BICUBIC), dtype=np.float32) / 32 - 4
    return tooth * 0.8 + pulp * 0.35


def main(layers: Path) -> None:
    paper = np.ones((SIZE, SIZE, 3), dtype=np.float32) * np.array(PAPER, dtype=np.float32)
    paper += (grain(SIZE, seed=17) * STRENGTH)[..., None]
    Image.fromarray(paper.clip(0, 255).astype(np.uint8)).save(layers / "paper.png", optimize=True)
    print("wrote paper.png")
    # Written again as plain sRGB PNGs, the way the asset compiler likes them.
    for variant in ("light", "dark", "tinted"):
        path = layers / f"flower-{variant}.png"
        Image.open(path).convert("RGBA").save(path, optimize=True)
        print(f"tidied {path.name}")


if __name__ == "__main__":
    main(Path(sys.argv[1]))
