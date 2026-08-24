# Security Policy

## Supported versions

Security fixes are provided for the latest published release.

| Version | Supported |
| --- | --- |
| 3.14.x | Yes |
| Earlier versions | Upgrade to the latest release |

## Reporting a vulnerability

Please do not publish vulnerability details in a regular issue.

Use GitHub's **Security → Report a vulnerability** flow for this repository. Include the affected version, macOS version, reproduction steps, impact, and any suggested mitigation. Reports will be acknowledged as soon as practical, investigated privately, and disclosed after a fix is available.

If private vulnerability reporting is temporarily unavailable, open a minimal issue asking the maintainer to establish a private contact channel. Do not include exploit details in that issue.

## Update integrity

Launchpad Classic releases use Sparkle's EdDSA signature verification for automatic updates. Release checksums are also published with each GitHub Release. The update-signing private key is not stored in this repository.
