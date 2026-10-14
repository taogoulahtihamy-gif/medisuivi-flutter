"""SMTP-only verification mailer; never log credentials or codes.

No email is sent unless this module is explicitly configured. Production
requires a separate security and provider review; this service fails closed.
"""
from __future__ import annotations

import os
import smtplib
from email.message import EmailMessage


def send_security_code(recipient: str, purpose: str, code: str) -> None:
    host = os.getenv("APP_SMTP_HOST", "").strip()
    sender = os.getenv("APP_SMTP_FROM", "").strip()
    port = int(os.getenv("APP_SMTP_PORT", "587"))
    username = os.getenv("APP_SMTP_USER", "").strip()
    password = os.getenv("APP_SMTP_PASSWORD", "")
    tls = os.getenv("APP_SMTP_STARTTLS", "true").lower() == "true"
    environment = os.getenv("APP_ENV", "production").lower()
    if not host or not sender or not (1 <= port <= 65535):
        raise RuntimeError("SMTP provider not configured")
    if not tls and not (environment == "development" and
                        host in {"127.0.0.1", "localhost", "mailpit"}):
        raise RuntimeError("Plain SMTP is restricted to local development")
    if bool(username) != bool(password):
        raise RuntimeError("Incomplete SMTP credentials")
    subjects = {
        "verify_email": "MediSuivi : vérifiez votre adresse e-mail",
        "reset_password": "MediSuivi : réinitialisation du mot de passe",
    }
    if purpose not in subjects:
        raise ValueError("Unknown email security purpose")
    message = EmailMessage()
    message["From"] = sender
    message["To"] = recipient
    message["Subject"] = subjects[purpose]
    if purpose == "verify_email":
        message.set_content(
            f"Votre code de vérification MediSuivi : {code}\n"
            "Ce code expire après 30 minutes. Si vous n'avez pas créé de "
            "compte, ignorez ce message.\n"
        )
    else:
        message.set_content(
            f"Votre code de récupération MediSuivi : {code}\n"
            "Ce code expire après 15 minutes. Si vous n'avez pas demandé "
            "cette opération, ignorez ce message.\n"
        )
    with smtplib.SMTP(host, port, timeout=10) as client:
        client.ehlo()
        if tls:
            client.starttls()
            client.ehlo()
        if username:
            client.login(username, password)
        client.send_message(message)
