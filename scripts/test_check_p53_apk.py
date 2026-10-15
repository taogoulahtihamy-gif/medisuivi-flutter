"""Regression checks: distinguish SDK source examples from application origins."""
import tempfile
import unittest
import zipfile
from pathlib import Path
from check_p53_apk import ORIGIN, validate


class ApkCheckTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.sources = self.root / 'lib'
        self.sources.mkdir()
        self.apk = self.root / 'fixture.apk'

    def bundle(self, payload=ORIGIN, private=False):
        with zipfile.ZipFile(self.apk, 'w') as archive:
            archive.writestr('assets/flutter_assets/kernel_blob.bin', payload)
            if private:
                archive.writestr('assets/.env', 'synthetic-only')

    def test_sdk_stack_trace_example_is_not_an_api_endpoint(self):
        self.bundle(ORIGIN + b'// _GalleryAppState (http://localhost:8080/main.dart.js)')
        validate(self.apk, self.sources)

    def test_missing_vercel_is_rejected(self):
        self.bundle(b'no configured API')
        with self.assertRaisesRegex(ValueError, 'Vercel'):
            validate(self.apk, self.sources)

    def test_old_api_endpoints_are_rejected(self):
        for url in [b'http://127.0.0.1:8027', b'https://old.onrender.com']:
            with self.subTest(url=url):
                self.bundle(ORIGIN + url)
                with self.assertRaisesRegex(ValueError, 'origin'):
                    validate(self.apk, self.sources)

    def test_local_application_url_on_any_port_is_rejected(self):
        self.bundle()
        (self.sources / 'api.dart').write_text("const url = 'http://localhost:8080';")
        with self.assertRaisesRegex(ValueError, 'source'):
            validate(self.apk, self.sources)

    def test_private_configuration_is_rejected(self):
        self.bundle(private=True)
        with self.assertRaisesRegex(ValueError, 'Private'):
            validate(self.apk, self.sources)


if __name__ == '__main__':
    unittest.main()
