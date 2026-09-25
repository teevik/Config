{
  inputs,
  pkgs,
  system,
  ...
}:
let
  upstream = import ./upstream.nix { inherit inputs pkgs system; };
  buildPkgs = import inputs.zed.inputs.nixpkgs { inherit system; };
  inherit (buildPkgs) lib;
  common = upstream.commonArgs;
  rustBin = inputs.zed.inputs.rust-overlay.lib.mkRustBin { } buildPkgs;
  toolchain = rustBin.fromRustupToolchainFile (inputs.zed.outPath + "/rust-toolchain.toml");
  source = builtins.path {
    path = inputs.zed.outPath;
    name = "source";
  };
  resolverSource =
    buildPkgs.runCommand "zed-cargo-nix-workspace"
      {
        nativeBuildInputs = [ (buildPkgs.python3.withPackages (p: [ p.tomli-w ])) ];
      }
      ''
        cp -r ${source} "$out"
        chmod -R u+w "$out"
        python ${./prepare-cargo-nix.py} "$out"
      '';
  # Force materialization before the native plugin opens filesystem paths.
  resolverInput = builtins.seq (builtins.readFile "${resolverSource}/Cargo.toml") resolverSource;
  licenses = upstream.overrideAttrs {
    pname = "zed-licenses";
    cargoArtifacts = null;
    doInstallCargoArtifacts = false;
    buildPhase = ''
      ALLOW_MISSING_LICENSES=yes bash script/generate-licenses
    '';
    installPhase = ''
      mkdir -p "$out"
      cp assets/licenses.md "$out/licenses.md"
    '';
    postFixup = "";
  };
  localSrc = import ./local-source.nix {
    pkgs = buildPkgs;
    inherit source;
  };
  rustFlags = [
    "-C"
    "symbol-mangling-version=v0"
    "--cfg"
    "tokio_unstable"
  ];
  lock = builtins.fromTOML (builtins.readFile (source + "/Cargo.lock"));
  gitSources = lib.listToAttrs (
    lib.concatMap (
      package:
      let
        match = builtins.match "git\\+(.*)#([^#]+)" (package.source or "");
      in
      lib.optional (match != null) (
        let
          url = builtins.head (lib.splitString "?" (builtins.elemAt match 0));
          rev = builtins.elemAt match 1;
        in
        {
          name = "${url}#${rev}";
          value = builtins.path {
            name = "source";
            path = builtins.fetchGit {
              inherit url rev;
              ref = rev;
              allRefs = true;
              submodules = true;
            };
          };
        }
      )
    ) lock.package
  );
  cargoNix = inputs.cargo-nix-plugin.lib {
    pkgs = buildPkgs;
    src = resolverInput;
    inherit localSrc gitSources;
    rootFeatures = [ "gpui_platform/runtime_shaders" ];
    extraCfgs = [ "tokio_unstable" ];
    buildRustCrateForPkgs =
      cratePkgs: base: args:
      ((base.override { stdenv = common.stdenv cratePkgs; }) (
        args
        // {
          rust = toolchain;
          cargo = toolchain;
          inherit (common) nativeBuildInputs buildInputs;
          dontUseCmakeConfigure = true;
          codegenUnits = if args.crateName == "zed" then 16 else 1;
          extraRustcOpts =
            rustFlags
            ++ [
              "-C"
              "embed-bitcode=yes"
            ]
            ++
              lib.optionals
                (builtins.elem args.crateName [
                  "zed"
                  "cli"
                ])
                [
                  "-C"
                  "lto=thin"
                ];
          extraRustcOptsForBuildRs = rustFlags;
          env =
            builtins.removeAttrs common.env [
              "FONTCONFIG_FILE"
              "RELEASE_VERSION"
              "ZED_COMMIT_SHA"
            ]
            // {
              LK_CUSTOM_WEBRTC = pkgs.livekit-libwebrtc;
            }
            //
              lib.optionalAttrs
                (builtins.elem args.crateName [
                  "zed"
                  "cli"
                ])
                {
                  inherit (common.env) RELEASE_VERSION ZED_COMMIT_SHA;
                };
          postPatch =
            lib.optionalString (
              args ? workspace_member
              && builtins.pathExists "${source}/${args.workspace_member}/Cargo.toml"
              && toString args.src == toString (localSrc args.workspace_member).src
            ) (localSrc args.workspace_member).postPatch
            + ''
              if [ -f crates/zed/RELEASE_CHANNEL ]; then
                echo stable > crates/zed/RELEASE_CHANNEL
              fi
            ''
            + lib.optionalString (args.crateName == "assets") ''
              cp ${licenses}/licenses.md assets/licenses.md
            ''
            + lib.optionalString (args.crateName == "cxx") ''
              # DEP_CXXBRIDGE1_HEADER must survive this crate's sandbox. The
              # plugin retains/remaps OUT_DIR, but not the unpacked source tree.
              substituteInPlace build.rs --replace-fail \
                'let cxx_h = manifest_dir.join("include").join("cxx.h");' \
                'let cxx_h = PathBuf::from(env::var_os("OUT_DIR").unwrap()).join("cxx.h");
                 std::fs::copy(manifest_dir.join("include/cxx.h"), &cxx_h).unwrap();'
            ''
            + lib.optionalString (args.crateName == "webrtc-sys") ''
              substituteInPlace webrtc-sys/build.rs --replace-fail \
                "cargo:rustc-link-lib=static=webrtc" "cargo:rustc-link-lib=dylib=webrtc"
              substituteInPlace webrtc-sys/build.rs --replace-fail \
                'add_gio_headers(&mut builder);' \
                'for lib_name in ["glib-2.0", "gio-2.0"] {
                  if let Ok(lib) = pkg_config::Config::new().cargo_metadata(false).probe(lib_name) {
                    for path in lib.include_paths { builder.include(&path); }
                  }
                }'
            '';
        }
        // lib.optionalAttrs (args.crateName == "zed") {
          # These libraries are dlopened; shrinking RPATH would remove them.
          dontPatchELF = true;
        }
        // lib.optionalAttrs (args.crateName == "webrtc-sys") {
          # C++ compilation finishes in configurePhase. Its generated crate
          # symlink points back into target/, which loops the plugin's later
          # object-file cleanup and output copying.
          preBuild = ''
            rm -rf target/build/webrtc-sys.out/cxxbridge/crate
          '';
        }
      )).override
        { debugInfo = 1; };
  };
in
assert buildPkgs.stdenv.hostPlatform.isLinux;
upstream.overrideAttrs (
  final: old: {
    pname = "zed-editor-cargo-nix";
    cargoArtifacts = null;
    doInstallCargoArtifacts = false;
    preBuild = "";
    buildPhase =
      assert cargoNix.apiLevel == cargoNix.resolverApiLevel;
      ''
        mkdir -p "$TARGET_DIR"
        cp ${cargoNix.workspaceMembers.zed.build}/bin/zed "$TARGET_DIR/zed"
        cp ${cargoNix.workspaceMembers.cli.build}/bin/cli "$TARGET_DIR/cli"
      '';
    passthru = (old.passthru or { }) // {
      inherit cargoNix resolverSource;
      inherit (final) cargoArtifacts;
    };
    meta = old.meta // {
      platforms = lib.platforms.linux;
    };
  }
)
