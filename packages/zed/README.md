# Zed builds

`zed` uses the installed `cargo-nix-plugin` and individual crate derivations.
The shared system package configuration selects this build. `zed-cargo-nix`
remains an alias for compatibility with the initial experimental package:

```sh
nix build .#zed
./result/bin/zed --version
```

The plugin must be loaded by the evaluating Nix. The existing
`packages/cargo-nix-plugin.nix` and NixOS settings already provide this.
`upstream.nix` retains the Crane build as the source of shared packaging and
as a fallback that can be imported directly.

The build reuses Zed's pinned toolchain, native dependencies, WebRTC patches,
release-channel setting, license generation, and final packaging. Workspace
crate sources are filtered individually, with explicit shared assets for the
crates that need them. Registry dependencies can be reused independently of
workspace changes.

`prepare-cargo-nix.py` creates a separate workspace for the resolver. It removes
development dependencies, limits roots to the application/CLI and their feature
entry point, and makes local path patches discoverable. The actual compiled
sources retain the original manifests. This avoids resolving every tool and
test in the upstream workspace as a production root. The plugin's remaining
host/target feature-unification differences still warrant care when updating it.

Two CXX adaptations support separate sandboxed builds: the `cxx` header is
exported from its retained `OUT_DIR`, and the generated WebRTC crate symlink is
removed after C++ compilation so the plugin's cleanup does not recurse through
the build tree.

The evaluation regression check verifies production features, dependency reuse,
and invalidation when a workspace crate's own source changes:

```sh
nix eval --impure --json --expr 'import ./tests/zed-cargo-nix.nix {}'
```

Evaluation materializes a resolver workspace and Git sources and may populate
the plugin's registry-index cache. A first compilation uses new derivation
outputs; it does not reuse Crane's dependency archive. No comparative timing
benchmark has been established.

Validated on `x86_64-linux`: the complete package builds, the packaged CLI reports
its version, the editor responds to `--help`, and all shared libraries resolve.
The local smoke test emits a nonfatal PCRE/libselinux symbol-version warning.
The user also verified that the graphical application works. An unchanged
second build performs no compilation.
