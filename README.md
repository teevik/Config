# NixOS Config

![image](https://github.com/user-attachments/assets/0ac9bd38-ffd5-432a-b7fe-a9820098e336)

## Installing a machine

Boot the target into any Linux with root SSH access, then run from this checkout:

```sh
just install <target-ip> <host>
```

`scripts/install.nu` drives [nixos-anywhere] in two steps: it boots the installer
and writes the detected hardware to `hosts/<host>/hardware.nix`, then partitions,
installs and reboots. Between the two it stages an installation seed through
`--extra-files`, in `/var/lib/install-seed` (root-only): `~/.ssh/id_rsa`,
`~/.ssh/id_rsa.pub`, `~/.config/sops/age/keys.txt`, and this checkout exactly as
it is, with Git metadata, uncommitted edits, new files and the fresh hardware
configuration. Ignored files stay behind.

The installed system adopts the seed during activation
(`modules/nixos/minimal/install-seed.nix`): once the user exists, each entry moves
into the home owned by the user, never replacing an existing path, and the seed
is deleted. This happens before sops-nix reads the age key and before Hjem links
dotfiles from `~/Documents/Config`, so the first boot needs no follow-up.
Commit and push the generated hardware configuration from either machine.

[nixos-anywhere]: https://github.com/nix-community/nixos-anywhere
