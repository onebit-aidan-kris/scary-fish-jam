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

        godot-start-debug = pkgs.godot-start.override { debug = true; };

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
          pkgs.godot-start.override {
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

        test-headless = pkgs.writeShellScriptBin "test-headless" ''
          ./scripts/test-headless --binary "${godot-start-debug}/bin/godot-start-bin" -- "$@"
        '';
      in
      {
        packages = {
          inherit (pkgs) godot-start;
          default = pkgs.godot-start;

          debug = godot-start-debug;

          web = pkgs.godot-start.override { preset = "Web"; };
          windows = pkgs.godot-start.override { preset = "Windows"; };

          linux-archive = mkArchive "Linux";
          macos-archive = mkArchive "macOS";
          windows-archive = mkArchive "Windows";
          web-archive = mkArchive "Web";

          inherit publish format test-headless;
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
