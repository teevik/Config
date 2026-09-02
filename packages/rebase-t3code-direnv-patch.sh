#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
patch_file="$script_dir/t3code-direnv.patch"
target_version=${1:-}

if [[ ! "$target_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+-nightly\.[0-9]{8}\.[0-9]+$ ]]; then
  printf 'Expected a T3 Code nightly version, got: %s\n' "$target_version" >&2
  exit 2
fi

base_version=$(
  sed -nE 's/^# t3code-base-version: (.+)$/\1/p' "$patch_file"
)

if [[ -z "$base_version" ]]; then
  printf 'Missing t3code-base-version metadata in %s\n' "$patch_file" >&2
  exit 2
fi

if [[ "$base_version" == "$target_version" ]]; then
  exit 0
fi

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/t3code-patch-rebase.XXXXXXXX")

cleanup() {
  chmod -R u+w "$work_dir" 2>/dev/null || true
  rm -rf -- "${work_dir:?}"
}
trap cleanup EXIT

base_tag="v$base_version"
target_tag="v$target_version"

git -C "$work_dir" init --quiet
git -C "$work_dir" remote add origin https://github.com/pingdotgg/t3code.git
git -C "$work_dir" fetch --quiet --filter=blob:none origin \
  "+refs/tags/$base_tag:refs/tags/$base_tag" \
  "+refs/tags/$target_tag:refs/tags/$target_tag"
git -C "$work_dir" config user.name t3code-patch-rebase
git -C "$work_dir" config user.email t3code-patch-rebase@localhost
git -C "$work_dir" switch --quiet --detach "$base_tag"

if ! patch --batch --no-backup-if-mismatch --strip=1 --directory="$work_dir" < "$patch_file"; then
  printf 'The existing direnv patch no longer applies to its recorded base tag %s.\n' \
    "$base_tag" >&2
  exit 1
fi

git -C "$work_dir" add --all
git -C "$work_dir" commit --quiet -m 'Apply the local project-environment workaround'
patch_commit=$(git -C "$work_dir" rev-parse HEAD)

git -C "$work_dir" switch --quiet --detach "$target_tag"
if ! git -C "$work_dir" cherry-pick --quiet "$patch_commit"; then
  # Import ordering changes frequently in T3 Code and can defeat Git's
  # line-based merge even when every edited statement still exists. Retry the
  # original patch with its full context relaxed, then validate and build the
  # result below. A genuine semantic conflict still fails without replacing the
  # existing patch.
  git -C "$work_dir" cherry-pick --abort

  if ! patch --batch --no-backup-if-mismatch --fuzz=3 --strip=1 \
    --directory="$work_dir" < "$patch_file"; then
    printf '\nThe direnv workaround has a semantic conflict with upstream %s.\n' \
      "$target_tag" >&2
    printf 'The existing patch was left unchanged.\n' >&2
    exit 1
  fi

  git -C "$work_dir" add --all
  git -C "$work_dir" commit --quiet -m 'Apply the local project-environment workaround'
fi

for driver in Claude Codex Cursor Grok OpenCode; do
  driver_file="$work_dir/apps/server/src/provider/Drivers/${driver}Driver.ts"
  if ! grep -qF 'makeProviderEnvironmentResolver(environment)' "$driver_file" || \
    ! grep -qF 'resolveEnvironment,' "$driver_file"; then
    printf 'The rebased patch did not wire project environments into %sDriver.ts.\n' \
      "$driver" >&2
    exit 1
  fi
done

if grep -R -n -E '^(<<<<<<<|=======|>>>>>>>)' \
  "$work_dir/apps/server/src/provider" >&2; then
  printf 'The rebased patch still contains merge-conflict markers.\n' >&2
  exit 1
fi

git -C "$work_dir" diff --check "$target_tag" HEAD

rebased_patch="$work_dir/t3code-direnv.patch"
{
  printf '# t3code-base-version: %s\n' "$target_version"
  git -C "$work_dir" diff --binary --full-index "$target_tag" HEAD
} > "$rebased_patch"

# A single space denotes an empty context line in Git's output. GNU patch also
# accepts the prefix omitted, which keeps this tracked patch whitespace-clean.
sed -i 's/^ $//' "$rebased_patch"

mv -- "$rebased_patch" "$patch_file"
printf 'Rebased %s onto %s.\n' "${patch_file##*/}" "$target_tag"
