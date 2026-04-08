# Contributing

Thanks for your interest in contributing to **Update GitHub Copilot Customizations**!

## Getting Started

1. Fork the repository.
2. Clone your fork locally.
3. Create a feature branch: `git checkout -b my-feature`
4. Make your changes and commit them: `git commit -m "feat: description"`
5. Push to your fork: `git push origin my-feature`
6. Open a Pull Request against `main`.

## Development

This is a composite GitHub Action. The core logic lives in [`scripts/update.sh`](scripts/update.sh).

To test changes locally you can source the environment variables defined in `action.yml` and run the script directly:

```bash
export GH_TOKEN="ghp_..."
export INPUT_VERSION="latest"
export INPUT_SOURCE_REPO="robertsinfosec/gh-copilot-customizations"
export INPUT_CREATE_PR="false"
export GITHUB_WORKSPACE="$(pwd)"
export GITHUB_OUTPUT="/dev/stdout"
bash scripts/update.sh
```

## Pull Request Guidelines

- Keep PRs focused — one logical change per PR.
- Follow the [style guide](STYLEGUIDE.md).
- Ensure your shell scripts pass `shellcheck` with no warnings.
- Update the README if your change adds or modifies inputs/outputs.

## Reporting Issues

Open an issue with a clear description, steps to reproduce, and any relevant logs.

## Code of Conduct

All participants are expected to follow our [Code of Conduct](CODE_OF_CONDUCT.md).
