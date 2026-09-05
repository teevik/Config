# Included by writeShellApplication, which supplies Bash strict mode and tools.
if (($# > 1)); then
  echo 'Usage: nix-lint [repository-root]' >&2
  exit 2
fi
cd -- "${1:-.}"

# The same source roots are used by checks/nix-lint.nix. Include new and
# untracked files locally, without scanning stowed dotfiles or dependencies.
file_list=$(mktemp -t nix-lint.XXXXXX)
trap 'rm -f -- "$file_list"' EXIT
find flake.nix formatter.nix checks hosts modules packages templates tests \
  -type f -name '*.nix' ! -path 'hosts/*/hardware.nix' -print0 > "$file_list"
mapfile -d '' -t files < "$file_list"

# Run both tools even when one fails. Never apply fixes in this command.
status=0
for file in "${files[@]}"; do
  statix check --config "$statix_config" "$file" || status=1
done
deadnix --fail -- "${files[@]}" || status=1
if ((status == 0)); then
  printf 'PASS: Statix and deadnix (%s Nix files; generated hardware excluded)\n' "${#files[@]}"
fi
exit "$status"
