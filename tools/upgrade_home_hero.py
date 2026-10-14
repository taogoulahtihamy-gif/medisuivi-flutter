"""Create a 4x local WebP from MediSuivi's original tiny home portrait.

This retains the same scene and never uploads a photo to a third-party API.
FSRCNN performs approximate super-resolution, not recovery of real lost detail.
Only a development-time tool; the Flutter app does not fetch models or images.
"""
from __future__ import annotations

import base64
from pathlib import Path
import re
from urllib.request import urlretrieve

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
INPUT = ROOT / "lib/core/assets/clinical_hero_photo.dart"
OUTPUT = ROOT / "assets/images/home_hero_hd.webp"
MODEL = ROOT / ".cache/fsrcnn_x4.pb"
MODEL_URL = (
    "https://raw.githubusercontent.com/Saafke/FSRCNN_Tensorflow/"
    "master/models/FSRCNN_x4.pb"
)


def main() -> None:
    source = INPUT.read_text(encoding="utf-8")
    match = re.search(
        r"clinicalHeroPhotoWebpBase64\s*=\s*'([A-Za-z0-9+/=]+)'", source
    )
    if not match:
        raise RuntimeError("Original WebP constant is missing")
    raw = base64.b64decode(match.group(1), validate=True)
    image = cv2.imdecode(np.frombuffer(raw, dtype=np.uint8), cv2.IMREAD_COLOR)
    if image is None or image.shape[:2] != (217, 300):
        raise RuntimeError("Unexpected hero image dimensions")

    MODEL.parent.mkdir(parents=True, exist_ok=True)
    if not MODEL.is_file():
        urlretrieve(MODEL_URL, MODEL)
    superres = cv2.dnn_superres.DnnSuperResImpl_create()
    superres.readModel(str(MODEL))
    superres.setModel("fsrcnn", 4)
    result = superres.upsample(image)
    assert result.shape[:2] == (868, 1200)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    ok = cv2.imwrite(str(OUTPUT), result, [cv2.IMWRITE_WEBP_QUALITY, 89])
    if not ok:
        raise RuntimeError("WebP write failed")
    print(f"{OUTPUT.relative_to(ROOT)}: {result.shape[1]}x{result.shape[0]}, {OUTPUT.stat().st_size} bytes")


if __name__ == "__main__":
    main()
