# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| v1.x    | Yes       |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it
responsibly. **Do not open a public issue.**

Instead, please use [GitHub Security Advisories](https://github.com/robertsinfosec/update-copilot-customizations-action/security/advisories/new)
to report the vulnerability privately.

You should receive an initial response within 72 hours. We will work with you
to understand the issue and coordinate a fix and disclosure timeline.

## Security Considerations

This action:

- **Downloads and extracts archives** from a configured source repository. Only
  `.tar.gz` assets from GitHub Releases are downloaded.
- **Requires a GitHub token** (`GITHUB_TOKEN` or a PAT) to access release assets
  and create pull requests. Treat tokens as secrets and never expose them in logs.
- **Modifies repository contents** by overlaying files into `.github/`. Review
  the resulting PR before merging to ensure no unexpected changes were introduced.

## Best Practices for Users

- Pin to a specific version tag (e.g. `@v1.0.0`) or use the major tag (`@v1`)
  rather than `@main` to avoid running untested changes.
- Use the default `create-pr: true` so changes can be reviewed before merging.
- Restrict the token's permissions to the minimum required (`contents: write`,
  `pull-requests: write`).
