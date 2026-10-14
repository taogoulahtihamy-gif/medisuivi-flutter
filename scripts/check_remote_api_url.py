#!/usr/bin/env python3
"""Fail closed for Web/APK build-time API URLs.

No secrets or network calls. Local/private IPs and HTTP must never appear
in an APK or public site built for the remote sandbox.
"""
from __future__ import annotations

import ipaddress
import sys
from urllib.parse import urlsplit


def verify(value: str) -> str:
    url = urlsplit(value.strip())
    if (url.scheme != "https" or not url.hostname or url.username
            or url.password or url.query or url.fragment or
            url.path not in {"", "/"} or url.port not in {None, 443}):
        raise ValueError("Remote API needs a bare HTTPS origin without secrets")
    host = url.hostname.lower()
    if (host in {"localhost", "127.0.0.1", "10.0.2.2"}
            or host.endswith(".local") or host.endswith(".localhost")
            or "." not in host or "*" in host):
        raise ValueError("Local/wildcard API address not permitted")
    try:
        address = ipaddress.ip_address(host)
    except ValueError:
        pass
    else:
        if not address.is_global:
            raise ValueError("Private or reserved IP API address forbidden")
    return value.strip().rstrip("/")


if __name__ == "__main__":
    try:
        verify(sys.argv[1] if len(sys.argv) == 2 else "")
    except (ValueError, IndexError) as exc:
        raise SystemExit(f"Remote API URL validation failed: {exc}")
    print("Remote HTTPS API origin validated (no local tunnel)")
