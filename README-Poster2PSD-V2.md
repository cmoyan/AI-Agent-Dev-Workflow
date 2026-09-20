# Poster2PSD V2 Alpha Bootstrap Branch

This branch is intentionally isolated from the repository main tree.

The Poster2PSD V2 source snapshot is stored as ordered Base64 chunks under `bootstrap/`.
GitHub Actions reconstructs the exact `tar.xz` snapshot, verifies SHA-256
`4388e4adea7919e6518325d5993e4d19a659f780a8b025c4cf71370af327222b`,
then builds and tests the Windows .NET 10 solution.

Product version: `0.1.0-alpha.1`
Master baseline: Poster2PSD V2 Master Development Outline v1.0 (LOCKED)
