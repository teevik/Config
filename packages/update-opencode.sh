#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
package_file="$repo_root/packages/opencode.nix"
desktop_file="$repo_root/packages/opencode-desktop.nix"

version="$(npm view '@opencode-ai/cli@beta' version)"
x86_64_hash="$(npm view "@opencode-ai/cli-linux-x64-baseline@$version" dist.integrity)"
aarch64_hash="$(npm view "@opencode-ai/cli-linux-arm64@$version" dist.integrity)"

mapfile -t desktop_release < <(
  curl -fsSL https://api.github.com/repos/anomalyco/opencode-beta/releases/latest \
    | node -e '
      let input = ""
      process.stdin.on("data", (chunk) => input += chunk)
      process.stdin.on("end", () => {
        const release = JSON.parse(input)
        const assets = [
          "opencode-desktop-linux-x86_64.AppImage",
          "opencode-desktop-linux-arm64.AppImage",
        ]
        console.log(release.tag_name)
        for (const name of assets) {
          const asset = release.assets.find((candidate) => candidate.name === name)
          if (!asset?.digest?.startsWith("sha256:")) {
            throw new Error(`release asset ${name} has no SHA-256 digest`)
          }
          console.log(asset.digest.slice("sha256:".length))
        }
      })
    '
)

desktop_version="${desktop_release[0]#v}"
if [[ "$desktop_version" != "$version" ]]; then
  echo "OpenCode CLI beta is $version but desktop beta is $desktop_version" >&2
  exit 1
fi

desktop_x86_64_hash="$(nix hash convert --hash-algo sha256 --to sri "${desktop_release[1]}")"
desktop_aarch64_hash="$(nix hash convert --hash-algo sha256 --to sri "${desktop_release[2]}")"

export OPENCODE_VERSION="$version"
export OPENCODE_X86_64_HASH="$x86_64_hash"
export OPENCODE_AARCH64_HASH="$aarch64_hash"
export OPENCODE_DESKTOP_X86_64_HASH="$desktop_x86_64_hash"
export OPENCODE_DESKTOP_AARCH64_HASH="$desktop_aarch64_hash"

perl - "$package_file" "$desktop_file" <<'PERL'
use strict;
use warnings;

my ($package_path, $desktop_path) = @ARGV;

sub read_file {
  my ($path) = @_;
  open my $input, '<', $path or die "cannot read $path: $!\n";
  local $/;
  my $source = <$input>;
  close $input;
  return $source;
}

sub write_file {
  my ($path, $source) = @_;
  my $temporary = "$path.tmp.$$";
  open my $output, '>', $temporary or die "cannot write $temporary: $!\n";
  print {$output} $source;
  close $output or die "cannot close $temporary: $!\n";
  rename $temporary, $path or die "cannot replace $path: $!\n";
}

my $package_source = read_file($package_path);
my $desktop_source = read_file($desktop_path);

my $package_changes = 0;
$package_changes += $package_source =~ s/version = "[^"]+";/version = "$ENV{OPENCODE_VERSION}";/;
$package_changes += $package_source =~ s/(packageName = "cli-linux-x64-baseline";\n\s+hash = ")[^"]+(";)/$1$ENV{OPENCODE_X86_64_HASH}$2/;
$package_changes += $package_source =~ s/(packageName = "cli-linux-arm64";\n\s+hash = ")[^"]+(";)/$1$ENV{OPENCODE_AARCH64_HASH}$2/;
die "expected to update three OpenCode CLI source fields, updated $package_changes\n"
  unless $package_changes == 3;

my $desktop_changes = 0;
$desktop_changes += $desktop_source =~ s/(arch = "x86_64";\n\s+hash = ")[^"]+(";)/$1$ENV{OPENCODE_DESKTOP_X86_64_HASH}$2/;
$desktop_changes += $desktop_source =~ s/(arch = "arm64";\n\s+hash = ")[^"]+(";)/$1$ENV{OPENCODE_DESKTOP_AARCH64_HASH}$2/;
die "expected to update two OpenCode desktop source fields, updated $desktop_changes\n"
  unless $desktop_changes == 2;

write_file($package_path, $package_source);
write_file($desktop_path, $desktop_source);
PERL

echo "Updated opencode2 CLI and desktop to $version"
