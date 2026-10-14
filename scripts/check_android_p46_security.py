#!/usr/bin/env python3
"""P4.6: fail CI if Android allows broad HTTP or backs up clinical app data.

Only parses manifest and XML policy files. Does not access Android devices,
credentials, app databases, the network, or patient records.
"""
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ANDROID = "{http://schemas.android.com/apk/res/android}"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"P4.6 Android policy FAILED: {message}")


def validate() -> None:
    manifest = ET.parse(
        ROOT / "android/app/src/main/AndroidManifest.xml"
    ).getroot()
    permissions = {
        item.get(ANDROID + "name")
        for item in manifest.findall("uses-permission")
    }
    require("android.permission.INTERNET" in permissions,
            "main manifest must declare INTERNET for HTTPS release")
    application = manifest.find("application")
    require(application is not None, "missing Android application")
    require(application.get(ANDROID + "allowBackup") == "false",
            "Android automatic backup must be disabled")
    require(application.get(ANDROID + "fullBackupContent") == "false",
            "legacy full backup must be disabled")
    require(
        application.get(ANDROID + "dataExtractionRules")
        == "@xml/medisuivi_data_extraction_rules",
        "Android 12+ data extraction rules must be configured",
    )
    require(application.get(ANDROID + "usesCleartextTraffic") != "true",
            "main manifest must not allow HTTP")
    require(application.get(ANDROID + "networkSecurityConfig") is None,
            "loopback exception must not be in release/main manifest")

    extraction = ET.parse(
        ROOT / "android/app/src/main/res/xml/medisuivi_data_extraction_rules.xml"
    ).getroot()
    require(extraction.tag == "data-extraction-rules",
            "unexpected Android extraction root")
    require(set(item.tag for item in extraction) ==
            {"cloud-backup", "device-transfer"},
            "cloud and D2D data transfer must be covered")
    for section in extraction:
        require(
            any(item.tag == "exclude"
                and item.get("domain") == "root"
                and item.get("path") == "."
                for item in section),
            f"{section.tag} must exclude app-private data",
        )
        require(not any(item.tag == "include" for item in section),
                f"{section.tag} must not include private data")

    debug = ET.parse(
        ROOT / "android/app/src/debug/AndroidManifest.xml"
    ).getroot()
    debug_app = debug.find("application")
    require(
        debug_app is not None and
        debug_app.get(ANDROID + "networkSecurityConfig")
        == "@xml/medisuivi_debug_network_security",
        "debug manifest must opt into restricted loopback policy",
    )

    policy = ET.parse(
        ROOT / "android/app/src/debug/res/xml/medisuivi_debug_network_security.xml"
    ).getroot()
    require(policy.tag == "network-security-config",
            "unexpected debug network-security-config root")
    base = policy.find("base-config")
    require(base is not None and
            base.get("cleartextTrafficPermitted") == "false",
            "debug HTTP base policy must remain disabled")
    domains = set()
    for item in policy.findall("domain-config"):
        require(item.get("cleartextTrafficPermitted") == "true",
                "only explicit debug domains may allow HTTP")
        for domain in item.findall("domain"):
            require(domain.get("includeSubdomains") != "true",
                    "wildcard debug cleartext domains forbidden")
            domains.add((domain.text or "").strip())
    require(domains == {"127.0.0.1", "localhost", "10.0.2.2"},
            f"debug cleartext hosts must be loopback/emulator only: {domains}")
    require(policy.find("debug-overrides") is None,
            "debug trust anchors may not bypass TLS")

    print("P4.6 Android policies: INTERNET, no backup, scoped debug HTTP OK")


if __name__ == "__main__":
    validate()
