"""Bundle DM Sans as an application font, without runtime network requests.

Source: Google Fonts /ofl/dmsans, licensed under SIL Open Font License 1.1.
Downloaded at build time only; no user/device data leaves the app.
"""
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
BASE = "https://raw.githubusercontent.com/google/fonts/main/ofl/dmsans/"
TARGET = ROOT / "assets/fonts"
FILES = {
    "DMSans-Variable.ttf": "DMSans%5Bopsz%2Cwght%5D.ttf",
    "OFL.txt": "OFL.txt",
}

def main():
    TARGET.mkdir(parents=True, exist_ok=True)
    for name, upstream in FILES.items():
        request = Request(BASE + upstream, headers={"User-Agent": "MediSuivi-font-build/1.0"})
        with urlopen(request, timeout=60) as response:
            data = response.read(3 * 1024 * 1024)
        if name.endswith(".ttf"):
            if data[:4] not in (b"\x00\x01\x00\x00", b"OTTO"):
                raise RuntimeError("Unexpected TrueType/OTF font signature")
            if len(data) < 100_000: raise RuntimeError("Font file too small")
        elif b"SIL OPEN FONT LICENSE" not in data.upper():
            raise RuntimeError("Missing required font license")
        (TARGET / name).write_bytes(data)
        print(f"Packaged {name}: {len(data)} bytes")

if __name__ == "__main__":
    main()
