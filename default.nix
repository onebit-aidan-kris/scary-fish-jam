{
  archive ? false,
  debug ? false,
  preset ? "Linux",

  callPackage,
  lib,
  stdenvNoCC,

  fontconfig,
  godot_4,
  makeWrapper,
  python3,
  steam-run-free,
  util-linux,
  zip,
}:
let
  strIf = b: flag: if b then flag else "";

  # NixOS and Web builds require wrapper
  wrapper = (preset == "Linux" || preset == "Web") && !archive;

  archiveBuildInputs = [
    zip
  ];
in
stdenvNoCC.mkDerivation {
  name = "godot-start";
  src = lib.cleanSource ./.;

  nativeBuildInputs = [
    godot_4
    (callPackage ./nix/install-export-templates.nix { })
    util-linux # getopt
    makeWrapper
  ]
  ++ (if archive then archiveBuildInputs else [ ]);

  buildPhase = ''
    TMPDIR="''${TMPDIR:-/tmp}"
    export HOME="$TMPDIR/home"
    export XDG_DATA_HOME="$HOME/.local/share"
    export FONTCONFIG_FILE=${fontconfig.out}/etc/fonts/fonts.conf
    export FONTCONFIG_PATH=${fontconfig.out}/etc/fonts/
    install-export-templates
    patchShebangs ./scripts/bld
    ./scripts/bld "${preset}" ${strIf archive "-z"} ${strIf wrapper "-w"} ${strIf debug "-d"}
  '';

  installPhase =
    if archive then
      ''
        mkdir -p $out/share
        mv build/* $out/share
      ''
    else
      ''
        mkdir -p $out/bin
        mv build/*/* $out/bin

        if [[ "${strIf wrapper "1"}" ]]; then
          if [[ ${preset} = Linux ]]; then
            wrapProgram $out/bin/godot-start --prefix PATH : ${lib.makeBinPath [ steam-run-free ]}
          elif [[ ${preset} = Web ]]; then
            wrapProgram $out/bin/godot-start --prefix PATH : ${lib.makeBinPath [ python3 ]}
          fi
        fi
      '';

  meta = {
    mainProgram = if archive then null else "godot-start";
    # description = "A short description of my application";
    # homepage = "https://github.com";
    # license = lib.licenses.mit;
  };
}
