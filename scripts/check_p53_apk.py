#!/usr/bin/env python3
"""Inspect the debug Flutter payload without printing binary content or secrets."""
import sys
import zipfile
from pathlib import Path

apk = Path(sys.argv[1])
assert apk.is_file() and apk.stat().st_size > 0, 'APK missing or empty'
with zipfile.ZipFile(apk) as archive:
    assert archive.testzip() is None, 'Invalid APK archive'
    payload = archive.read('assets/flutter_assets/kernel_blob.bin')
    assert b'https://medisuivi-api-staging.vercel.app' in payload, 'Vercel origin missing'
    for forbidden in (b'onrender.com', b'http://127.0.0.1:', b'http://localhost:', b'http://10.0.2.2:'):
        assert forbidden not in payload, 'Unexpected API origin in Flutter payload'
    for name in archive.namelist():
        assert not name.endswith(('.env', '.jks', '.keystore', '.p12')), 'Private configuration packaged'
print('P5.3 APK: valid ZIP, Vercel origin present, no local/Render API URL or private configuration file')
