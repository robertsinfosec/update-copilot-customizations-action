#!/usr/bin/env bash
# update.sh — downloads and overlays Copilot customization files from a
# centralized governance repository into the consumer's repository.
set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()  { echo "::notice::$*"; }
error() { echo "::error::$*" >&2; }

# ---------------------------------------------------------------------------
# Inputs (injected via environment variables by action.yml)
# ---------------------------------------------------------------------------
VERSION="${INPUT_VERSION:-latest}"
SOURCE_REPO="${INPUT_SOURCE_REPO:-robertsinfosec/gh-copilot-customizations}"
CREATE_PR="${INPUT_CREATE_PR:-true}"
PR_BRANCH="${INPUT_PR_BRANCH:-update-copilot-customizations}"
PR_BASE="${INPUT_PR_BASE:-}"

# ---------------------------------------------------------------------------
# Step 1: Resolve version
# ---------------------------------------------------------------------------
if [ "${VERSION}" = "latest" ]; then
  info "Resolving latest release from ${SOURCE_REPO} …"
  VERSION="$(gh api "/repos/${SOURCE_REPO}/releases/latest" --jq '.tag_name')" || {
    error "Failed to resolve latest release from ${SOURCE_REPO}. Does the repo have any releases?"
    exit 1
  }
fi

if [ -z "${VERSION}" ]; then
  error "Could not determine a version to install."
  exit 1
fi

info "Installing version: ${VERSION}"

# ---------------------------------------------------------------------------
# Step 2: Download the release artifact
# ---------------------------------------------------------------------------
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

DOWNLOAD_DIR="${WORK_DIR}/download"
EXTRACT_DIR="${WORK_DIR}/extract"
mkdir -p "${DOWNLOAD_DIR}" "${EXTRACT_DIR}"

REPO_NAME="${SOURCE_REPO##*/}"
ASSET_PATTERN="${REPO_NAME}-*.tar.gz"

info "Downloading release assets for ${VERSION} from ${SOURCE_REPO} …"
gh release download "${VERSION}" \
  --repo "${SOURCE_REPO}" \
  --pattern "${ASSET_PATTERN}" \
  --dir "${DOWNLOAD_DIR}" || {
  error "Failed to download release assets for ${VERSION} from ${SOURCE_REPO}."
  exit 1
}

TARBALL="$(find "${DOWNLOAD_DIR}" -name "${ASSET_PATTERN}" -print -quit)"
if [ -z "${TARBALL}" ]; then
  error "No release asset matching ${ASSET_PATTERN} was found for ${VERSION}."
  exit 1
fi

info "Downloaded: $(basename "${TARBALL}")"

# ---------------------------------------------------------------------------
# Step 3: Extract the archive
# ---------------------------------------------------------------------------
info "Extracting archive …"
tar -xzf "${TARBALL}" -C "${EXTRACT_DIR}" || {
  error "Failed to extract ${TARBALL}."
  exit 1
}

GITHUB_DIR="$(find "${EXTRACT_DIR}" -type d -name ".github" | head -n 1)"
if [ -z "${GITHUB_DIR}" ]; then
  error "No .github/ directory found inside the archive."
  exit 1
fi

# ---------------------------------------------------------------------------
# Step 4: Branch setup — switch branches BEFORE overlaying files
# ---------------------------------------------------------------------------
WORKSPACE="${GITHUB_WORKSPACE:-.}"

if [ "${CREATE_PR}" = "true" ]; then
  # Configure git identity if not already set
  git config --get user.email > /dev/null 2>&1 || git config user.email "github-actions[bot]@users.noreply.github.com"
  git config --get user.name  > /dev/null 2>&1 || git config user.name  "github-actions[bot]"

  # Determine base branch
  if [ -z "${PR_BASE}" ]; then
    PR_BASE="$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")"
  fi

  # Always rebuild the automation branch from the latest base branch state.
  git fetch origin "${PR_BASE}" || {
    error "Failed to fetch base branch origin/${PR_BASE}."
    exit 1
  }

  git checkout -B "${PR_BRANCH}" "origin/${PR_BASE}" || {
    error "Failed to reset ${PR_BRANCH} from origin/${PR_BASE}."
    exit 1
  }
fi

# ---------------------------------------------------------------------------
# Step 5: Overlay — copy files into the workspace, never delete consumer files
# ---------------------------------------------------------------------------
FILES_CHANGED=0
CHANGED_LIST=""

info "Overlaying .github/ files into ${WORKSPACE} …"

while IFS= read -r -d '' src_file; do
  rel_path="${src_file#"${GITHUB_DIR}/"}"
  dest_file="${WORKSPACE}/.github/${rel_path}"

  # Ensure destination directory exists
  mkdir -p "$(dirname "${dest_file}")"

  # Copy (overwrite if exists, add if new)
  cp -f "${src_file}" "${dest_file}"
  FILES_CHANGED=$((FILES_CHANGED + 1))
  CHANGED_LIST="${CHANGED_LIST}  - .github/${rel_path}\n"
done < <(find "${GITHUB_DIR}" -type f -print0)

info "Files added/updated: ${FILES_CHANGED}"

# ---------------------------------------------------------------------------
# Step 6: Report
# ---------------------------------------------------------------------------
if [ "${FILES_CHANGED}" -eq 0 ]; then
  info "No files were changed."
fi

# ---------------------------------------------------------------------------
# Step 7: Commit and push
# ---------------------------------------------------------------------------
if [ "${CREATE_PR}" = "true" ]; then
  git add -- ".github/"

  if git diff --cached --quiet; then
    info "No changes to commit — already up to date."
    PR_NUMBER=""
  else
    PR_TITLE="chore: update Copilot customizations to ${VERSION}"
    PR_BODY="$(printf "## Copilot Customizations Update\n\nInstalled version **%s** from \`%s\`.\n\n### Files added/updated\n\n%b" \
      "${VERSION}" "${SOURCE_REPO}" "${CHANGED_LIST}")"

    git commit -m "${PR_TITLE}"
    git push --force-with-lease origin "${PR_BRANCH}"

    # Check whether a PR already exists for this branch
    EXISTING_PR="$(gh pr list \
      --head "${PR_BRANCH}" \
      --base "${PR_BASE}" \
      --state open \
      --json number \
      --jq '.[0].number' 2>/dev/null || echo "")"

    if [ -n "${EXISTING_PR}" ] && [ "${EXISTING_PR}" != "null" ]; then
      info "PR #${EXISTING_PR} already exists — updating body."
      gh pr edit "${EXISTING_PR}" --body "${PR_BODY}"
      PR_NUMBER="${EXISTING_PR}"
    else
      PR_URL="$(gh pr create \
        --title "${PR_TITLE}" \
        --body  "${PR_BODY}" \
        --base  "${PR_BASE}" \
        --head  "${PR_BRANCH}")"
      PR_NUMBER="${PR_URL##*/}"
      info "Created PR #${PR_NUMBER}"
    fi
  fi

  echo "pr-number=${PR_NUMBER}" >> "${GITHUB_OUTPUT}"
else
  # Direct commit to the current branch
  git config --get user.email > /dev/null 2>&1 || git config user.email "github-actions[bot]@users.noreply.github.com"
  git config --get user.name  > /dev/null 2>&1 || git config user.name  "github-actions[bot]"

  git add -- ".github/"

  if git diff --cached --quiet; then
    info "No changes to commit — already up to date."
  else
    git commit -m "chore: update Copilot customizations to ${VERSION}"
    git push
  fi
fi

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
echo "version=${VERSION}"          >> "${GITHUB_OUTPUT}"
echo "files-changed=${FILES_CHANGED}" >> "${GITHUB_OUTPUT}"
