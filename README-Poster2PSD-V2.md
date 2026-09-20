# Poster2PSD V2 Alpha 0.1.0-alpha.2 Dual Regression

This isolated branch carries a canonical Poster2PSD source snapshot and a Windows CI pipeline.

Canonical source tar.xz SHA-256:
`3b40b0bd7551b1fbb07349c8432847f8b12964ff6665d3b684bb89d4d0a4db85`

A run is acceptable only when BOTH gates pass:
1. Source regression: static parse, restore, vulnerable dependency audit, warnings-as-errors solution build, xUnit.
2. EXE artifact regression: 9 PE executables, ProductVersion/self-tests, payload parity, isolated install/repair/uninstall, data-preservation, release hash verification.

Photoshop real-host validation is explicitly excluded from CI and remains NOT VERIFIED until a Photoshop host regression is executed.
