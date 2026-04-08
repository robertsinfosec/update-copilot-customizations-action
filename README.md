# Update GitHub Copilot Customizations

[![CI](https://github.com/robertsinfosec/update-copilot-customizations-action/actions/workflows/test.yml/badge.svg)](https://github.com/robertsinfosec/update-copilot-customizations-action/actions/workflows/test.yml)

A GitHub Action that downloads a release artifact from a centralized governance repository ([`robertsinfosec/gh-copilot-customizations`](https://github.com/robertsinfosec/gh-copilot-customizations)) and overlays the `.github/` customization files — including instructions, prompts, agents, skills, and `copilot-instructions.md` — into the consumer's repository. This allows organizations to distribute and keep Copilot customization files consistent across many repositories from a single source of truth, without overwriting any custom files the consumer has added themselves.

---

## Quick Start

```yaml
name: Update Copilot Customizations
on:
  workflow_dispatch:
    inputs:
      version:
        description: "Version to install (e.g. v26.408.559 or latest)"
        default: "latest"

permissions:
  contents: write
  pull-requests: write

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: robertsinfosec/update-copilot-customizations-action@v1
        with:
          version: ${{ inputs.version || 'latest' }}
      # PR is created automatically
```

---

## Advanced Examples

### Scheduled weekly updates

```yaml
name: Weekly Copilot Customizations Update
on:
  schedule:
    - cron: '0 9 * * 1'   # Every Monday at 09:00 UTC
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: robertsinfosec/update-copilot-customizations-action@v1
        with:
          version: latest
          pr-branch: auto/copilot-customizations
```

### Pinned version

```yaml
name: Install Pinned Copilot Customizations
on:
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - id: update
        uses: robertsinfosec/update-copilot-customizations-action@v1
        with:
          version: v26.408.559
      - run: echo "Installed ${{ steps.update.outputs.version }}, PR ${{ steps.update.outputs.pr-number }}"
```

---

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `version` | no | `latest` | Release version to install (e.g. `v26.408.559` or `latest`) |
| `source-repo` | no | `robertsinfosec/gh-copilot-customizations` | GitHub repo to download releases from |
| `token` | no | `${{ github.token }}` | GitHub token for downloading release assets and creating PRs |
| `create-pr` | no | `true` | Whether to open a PR with the changes instead of committing directly |
| `pr-branch` | no | `update-copilot-customizations` | Branch name for the PR |
| `pr-base` | no | `${{ github.event.repository.default_branch }}` | Base branch for the PR |

## Outputs

| Output | Description |
|--------|-------------|
| `version` | The resolved version that was installed |
| `pr-number` | PR number if one was created (empty otherwise) |
| `files-changed` | Number of files added or updated |

---

## What files get installed?

The action installs everything found under `.github/` in the release archive from the source repository. This typically includes:

- `.github/copilot-instructions.md`
- `.github/instructions/` — Copilot instruction files
- `.github/prompts/` — reusable prompt files
- `.github/agents/` — agent definition files
- `.github/skills/` — skill definition files

**Consumer files are preserved.** The action only overwrites files whose paths match files in the archive, and adds any new files. It never deletes files that exist in the consumer's repository but are absent from the archive.

---

## Permissions

The following permissions must be granted to the workflow token:

```yaml
permissions:
  contents: write       # needed to push commits / branches
  pull-requests: write  # needed to open or update PRs
```

If you use a custom `token` input (e.g. a PAT), ensure it has the equivalent scopes (`repo` for private repos, or `public_repo` for public repos).

---

## License

[MIT](LICENSE)
