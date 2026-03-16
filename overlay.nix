final: prev:
let
  preset =
    {
      "x86_64-linux" = "Linux";
      "aarch64-linux" = "Linux";
      "x86_64-darwin" = "macOS";
      "aarch64-darwin" = "macOS";
    }
    .${prev.stdenv.hostPlatform.system};
in
{
  godot-start = prev.callPackage ./. {
    inherit preset;
  };
}
