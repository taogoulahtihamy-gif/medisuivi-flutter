"""Fetch licensed public clinical portraits at build-time, never at patient runtime.

All images are saved to local Flutter assets for offline use. No patients,
profiles or telemetry are sent to a third-party image provider.
"""
from __future__ import annotations

import io
from pathlib import Path
from urllib.request import Request, urlopen
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/images/onboarding"
PHOTO_IDS = {
    "splash": 19957218,
    "records": 5452252,
    "followup": 5214997,
    "privacy": 32254527,
    "access": 19957215,
}

def bundle(name: str, photo_id: int) -> None:
    url = (
        f"https://images.pexels.com/photos/{photo_id}/pexels-photo-{photo_id}.jpeg"
        "?auto=compress&cs=tinysrgb&w=1440&h=2200&fit=crop"
    )
    request = Request(url, headers={"User-Agent": "MediSuivi-build-assets/1.0"})
    with urlopen(request, timeout=45) as response:
        data = response.read(12 * 1024 * 1024)
        if not response.headers.get("Content-Type", "").startswith("image/"):
            raise RuntimeError(f"{name}: nonimage response")
    with Image.open(io.BytesIO(data)) as original:
        photo = original.convert("RGB")
        if photo.width < 720 or photo.height < 1000:
            raise RuntimeError(f"{name}: low-resolution source {photo.size}")
        OUT.mkdir(parents=True, exist_ok=True)
        file = OUT / f"{name}.webp"
        photo.save(file, format="WEBP", quality=88, method=5)
        if file.stat().st_size < 15000:
            raise RuntimeError(f"{name}: unexpectedly small file")
        print(f"{file.relative_to(ROOT)}: {photo.width}x{photo.height}, {file.stat().st_size} bytes")

def main() -> None:
    for name, id_ in PHOTO_IDS.items():
        bundle(name, id_)

if __name__ == "__main__":
    main()
