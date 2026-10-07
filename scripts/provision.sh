#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
action=${1:-}
target=${2:-}
host=${3:-}

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

[[ -n "$target" && "$target" != -* && "$target" != *@* ]] || fail "Specify the target hostname or IP, without a username."
stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT
umask 077

case "$action" in
    install)
        [[ $# == 3 && "$host" =~ ^[a-zA-Z0-9_-]+$ && -f "$root/hosts/$host/disk-config.nix" ]] || fail "Specify an installable host from hosts/."
        for key in "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_rsa.pub" "$HOME/.config/sops/age/keys.txt"; do
            [[ -f "$key" && -r "$key" ]] || fail "Required installation key is missing or unreadable: $key"
        done
        install -d -m 0700 "$stage/home/teevik/.ssh" "$stage/home/teevik/.config/sops/age"
        install -m 0600 "$HOME/.ssh/id_rsa" "$stage/home/teevik/.ssh/id_rsa"
        install -m 0644 "$HOME/.ssh/id_rsa.pub" "$stage/home/teevik/.ssh/id_rsa.pub"
        install -m 0600 "$HOME/.config/sops/age/keys.txt" "$stage/home/teevik/.config/sops/age/keys.txt"
        cd -- "$root"
        nix run github:nix-community/nixos-anywhere -- \
            --build-on local \
            --no-substitute-on-destination \
            --phases kexec,disko,install \
            --extra-files "$stage" \
            --generate-hardware-config nixos-generate-config "./hosts/$host/hardware.nix" \
            --flake ".#$host" \
            "root@$target"
        printf 'Installed without rebooting. Boot the target, then run: just provision %s\n' "$target"
        ;;
    provision)
        [[ $# == 2 ]] || fail "Usage: provision.sh provision TARGET-IP"
        [[ -d "$root/.git" && ! -L "$root/.git" ]] || fail "Provisioning requires a normal Git checkout, not a linked worktree."
        [[ ! -f "$root/.gitmodules" ]] || fail "Provisioning submodules is not supported by this checkout snapshot."
        # Include working-tree edits, generated hardware, and nonignored new files.
        # Keep Git metadata for subsequent updates; omit ignored build artifacts.
        git -C "$root" ls-files --cached --others --exclude-standard -z > "$stage/files"
        printf '.git\0' > "$stage/archive-files"
        while IFS= read -r -d '' file; do
            if [[ -e "$root/$file" || -L "$root/$file" ]]; then
                printf '%s\0' "$file" >> "$stage/archive-files"
            fi
        done < "$stage/files"
        tar --create --file "$stage/checkout.tar" --directory "$root" \
            --null --verbatim-files-from --files-from "$stage/archive-files"

        # This script intentionally uses no single quotes: SSH passes it inside
        # single quotes to bash, and the archive is supplied on standard input.
        remote_script=$(cat <<'REMOTE'
set -euo pipefail
[[ -f /etc/NIXOS ]] || { echo "Target is not NixOS." >&2; exit 1; }
source /etc/os-release
[[ ${VARIANT_ID:-} != installer ]] || { echo "Boot the installed system before provisioning." >&2; exit 1; }
home=$(getent passwd teevik | cut -d : -f 6)
[[ "$home" == /home/teevik ]] || { echo "Expected installed user teevik with home /home/teevik." >&2; exit 1; }
group=$(id -gn teevik)
destination="$home/Documents/Config"
[[ ! -e "$destination" && ! -L "$destination" ]] || { echo "Refusing to replace an existing Config checkout." >&2; exit 1; }
mkdir -p "$home/Documents"
staging=$(mktemp -d "$home/Documents/.Config-provision.XXXXXX")
cleanup() { rm -rf -- "$staging"; }
trap cleanup EXIT
tar --extract --file - --directory "$staging" --no-same-owner
[[ -d "$staging/.git" ]] || { echo "Checkout archive is missing Git metadata." >&2; exit 1; }
chown -R "teevik:$group" "$staging"
chown "teevik:$group" "$home/Documents"
for directory in "$home/.ssh" "$home/.config" "$home/.config/sops" "$home/.config/sops/age"; do
    if [[ -d "$directory" ]]; then chown "teevik:$group" "$directory"; fi
done
for directory in "$home/.ssh" "$home/.config/sops/age"; do
    if [[ -d "$directory" ]]; then chmod 0700 "$directory"; fi
done
for key in "$home/.ssh/id_rsa" "$home/.ssh/id_rsa.pub" "$home/.config/sops/age/keys.txt"; do
    if [[ -f "$key" ]]; then chown "teevik:$group" "$key"; fi
done
for key in "$home/.ssh/id_rsa" "$home/.config/sops/age/keys.txt"; do
    if [[ -f "$key" ]]; then chmod 0600 "$key"; fi
done
mv -T --no-clobber -- "$staging" "$destination"
[[ ! -d "$staging" ]] || { echo "Destination appeared during provisioning; left it unchanged." >&2; exit 1; }
# First boot had no checkout sources; activate links now that they are present.
systemctl restart hjem-activate@teevik.service hjem-reload@teevik.service hjem-update-state@teevik.service
echo "Provisioned the local checkout. Declarative dotfile links now point to it."
REMOTE
)
        ssh -- "root@$target" "bash -c '$remote_script'" < "$stage/checkout.tar"
        ;;
    *) fail "Usage: provision.sh install TARGET-IP HOST | provision TARGET-IP" ;;
esac
