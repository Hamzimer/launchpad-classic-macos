# Contributing to Launchpad Classic

Thank you for helping improve Launchpad Classic. Bug reports, accessibility feedback, translations, performance investigations, documentation fixes, and focused code contributions are welcome.

## Before opening an issue

1. Search existing issues to avoid duplicates.
2. Confirm the problem still occurs in the latest release.
3. Remove personal information from screenshots and logs.
4. Use the bug or feature template and complete the requested fields.

Security vulnerabilities must follow [SECURITY.md](SECURITY.md) and must not be posted in a public issue.

## Development setup

Requirements:

- macOS 14 or later
- Xcode command-line tools with Swift 6

Build and run:

```sh
git clone https://github.com/Hamzimer/launchpad-classic-macos.git
cd launchpad-classic-macos
./build-app.sh
open "dist/Launchpad Classic.app"
```

Run the quality suite before submitting a change:

```sh
./run-quality-tests.sh
```

## Pull requests

- Keep each pull request focused on one problem.
- Explain the user-visible change and how it was verified.
- Add or update tests for behavior changes and edge cases.
- Avoid force-unwrapping, force-casting, hardcoded secrets, UI-thread I/O, and unrelated formatting changes.
- Preserve English, Japanese, and Traditional Chinese behavior when changing visible text.
- Attach before-and-after screenshots for UI changes.

By contributing, you agree that your contribution is provided under the repository's [MIT License](LICENSE).
