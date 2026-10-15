#!/usr/bin/env python3
"""Inspect debug assets and application origins without logging binary content.

Debug kernels embed SDK sources, including Flutter's localhost:8080 stack-trace
examples. Those are not API configuration. Check all application sources for
local URLs, and reject the historical API endpoints in the compiled payload.
The Android integration test additionally asserts DevAuthApi.devBaseUrl at runtime.
"""
import re
import sys
import zipfile
from pathlib import Path

ORIGIN = b'https://medisuivi-api-staging.vercel.app'
LOCAL_URL = re.compile(r'http[s]?://(?:localhost|127\.0\.0\.1|10\.0\.2\.2)(?=[:/\s\'\"])')


def validate(apk: Path, sources: Path) -> None:
    if not apk.is_file() or apk.stat().st_size == 0:
        raise ValueError('APK missing or empty')
    for source in sources.rglob('*.dart'):
        text = source.read_text()
        if 'onrender.com' in text or LOCAL_URL.search(text):
            raise ValueError('Unexpected API origin in application source')
    with zipfile.ZipFile(apk) as archive:
        if archive.testzip() is not None:
            raise ValueError('Invalid APK archive')
        payload = archive.read('assets/flutter_assets/kernel_blob.bin')
        if ORIGIN not in payload:
            raise ValueError('Vercel origin missing')
        for forbidden in (b'onrender.com', b'http://127.0.0.1:8027',
                          b'http://localhost:8027', b'http://10.0.2.2:8027'):
            if forbidden in payload:
                raise ValueError('Unexpected API origin in Flutter payload')
        for name in archive.namelist():
            if name.endswith(('.env', '.jks', '.keystore', '.p12')):
                raise ValueError('Private configuration packaged')


if __name__ == '__main__':
    validate(Path(sys.argv[1]), Path(__file__).resolve().parents[1] / 'lib')
    print('P5.3 APK: valid ZIP, Vercel origin present, application origins checked, no private configuration file')
