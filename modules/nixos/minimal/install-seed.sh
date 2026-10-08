# shellcheck shell=bash
# Adopt what `just install` staged for a new machine: SEED mirrors HOME.
# Usage: install-seed.sh SEED HOME USER GROUP
#
# Each staged entry moves into HOME, owned by USER:GROUP, unless that path
# already exists. Existing directories are merged into, except checkouts:
# a repository is adopted whole or not at all. Nothing is ever replaced.
# SEED is removed afterwards so private key copies don't linger; a failure
# keeps it for the next activation instead.
set -euo pipefail
shopt -s dotglob nullglob

seed=$1
home=$2
owner=$3:$4

[[ -d $seed ]] || exit 0
[[ -d $home ]] || { echo "install seed: $home does not exist yet" >&2; exit 1; }

adopt() {
    local source=$seed/$1 target=$home/$1
    if [[ ! -e $target && ! -L $target ]]; then
        chown -R -- "$owner" "$source"
        mv -T -- "$source" "$target"
    elif [[ -d $source && -d $target && ! -L $target && ! -e $source/.git ]]; then
        local entry
        for entry in "$source"/*; do
            adopt "$1/${entry##*/}"
        done
    else
        echo "install seed: keeping existing $target" >&2
    fi
}

echo "adopting installation seed..."
for entry in "$seed"/*; do
    adopt "${entry##*/}"
done
rm -rf -- "$seed"
