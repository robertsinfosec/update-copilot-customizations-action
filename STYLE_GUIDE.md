# Style Guide

## Shell Scripts

This project's core logic is written in Bash. Follow these conventions:

### General

- Use `#!/usr/bin/env bash` as the shebang.
- Start scripts with `set -euo pipefail`.
- Pass [ShellCheck](https://www.shellcheck.net/) with zero warnings.

### Naming

- **Variables**: `UPPER_SNAKE_CASE` for exported/environment variables, `lower_snake_case` for local variables.
- **Functions**: `lower_snake_case`.
- **Files**: lowercase with hyphens (e.g. `update.sh`).

### Quoting & Substitution

- Always double-quote variable expansions: `"${VAR}"`.
- Use `$()` for command substitution, not backticks.
- Use `[[ ]]` for conditionals instead of `[ ]`.

### Structure

- Group related logic under comment banners (`# --- Section ---`).
- Keep functions small and focused.
- Use `local` for function-scoped variables.

### Error Handling

- Use `|| { error "message"; exit 1; }` for critical commands.
- Prefer `trap` for cleanup of temporary files.

## Markdown

- Use ATX-style headings (`#`, `##`, etc.).
- One sentence per line (for cleaner diffs).
- Use fenced code blocks with a language identifier (` ```yaml `, ` ```bash `).
- Keep lines under 120 characters where practical.

## Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new input for custom branch prefix
fix: handle missing .github/ directory in archive
docs: update README with scheduled workflow example
chore: bump CI action versions
```
