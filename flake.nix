{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    flake-utils.lib.eachSystem supportedSystems (
      system:
      let
        localOverlay = import ./overlay.nix;

        pkgs = import nixpkgs {
          inherit system;
          overlays = [ localOverlay ];
        };

        scary-fish-jam-debug = pkgs.scary-fish-jam.override { debug = true; };

        devPkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true; # required for aseprite
        };

        baseDevShell = devPkgs.mkShellNoCC {
          buildInputs = with devPkgs; [
            (callPackage ./nix/install-export-templates.nix { })
            butler # itch.io uploader
            gdscript-formatter
            godot_4
            python3
            steam-run-free
            zip
          ];

          shellHook = ''
            PATH="$PATH:$PWD/scripts"
          '';
        };

        mkArchive =
          preset:
          pkgs.scary-fish-jam.override {
            inherit preset;
            archive = true;
          };

        writeScript =
          runtimeInputs: name: text:
          pkgs.writeShellApplication {
            inherit name runtimeInputs text;
          };

        publish = writeScript [ pkgs.butler ] "publish" ''
          set -eu
          pub() {
            CHANNEL="$1"
            ZIP="$2"
            (
                set -x
                butler push "$ZIP" "$BUTLER_TARGET:$CHANNEL"
            )
          }

          pub web "${self.packages.${system}.web-archive}"
          pub windows "${self.packages.${system}.windows-archive}"
          pub linux "${self.packages.${system}.linux-archive}"
          pub macos "${self.packages.${system}.macos-archive}"
        '';

        format = writeScript [ pkgs.gdscript-formatter ] "format" ''
          ./scripts/format "$@"
        '';

        lint = writeScript [ pkgs.gdscript-formatter ] "lint" ''
          ./scripts/format lint -v
          ./scripts/check-imports
        '';

        test-headless = pkgs.writeShellScriptBin "test-headless" ''
          ./scripts/test-headless --binary "${scary-fish-jam-debug}/bin/scary-fish-jam" -- "$@"
          ./scripts/test-headless --binary "${pkgs.scary-fish-jam}/bin/scary-fish-jam" -- "$@"
        '';
      in
      {
        packages = {
          inherit (pkgs) scary-fish-jam;
          default = pkgs.scary-fish-jam;

          debug = scary-fish-jam-debug;

          web = pkgs.scary-fish-jam.override { preset = "Web"; };
          windows = pkgs.scary-fish-jam.override { preset = "Windows"; };

          linux-archive = mkArchive "Linux";
          macos-archive = mkArchive "macOS";
          windows-archive = mkArchive "Windows";
          web-archive = mkArchive "Web";

          inherit
            publish
            format
            lint
            test-headless
            ;
        };

        devShells = {
          default = baseDevShell;

          full = baseDevShell.overrideAttrs (oldAttrs: {
            buildInputs =
              oldAttrs.buildInputs
              ++ (with devPkgs; [
                aseprite # Requires large local build
              ]);
          });
        };

        formatter = pkgs.nixfmt;
      }
    );
}
