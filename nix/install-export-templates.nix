{
  writeShellScriptBin,
  godot_4-export-templates-bin,
}:
let
  versionDir = builtins.replaceStrings [ "-" ] [ "." ] godot_4-export-templates-bin.version;
in
writeShellScriptBin "install-export-templates" ''
  EXPORT_TEMPLATES_DIR=''${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates
  TEMPLATE_LINK=$EXPORT_TEMPLATES_DIR/${versionDir}
  if [ -e "$TEMPLATE_LINK" ]; then
      echo $TEMPLATE_LINK already installed
  else
      mkdir -p $EXPORT_TEMPLATES_DIR
      ln -s ${godot_4-export-templates-bin}/share/godot/export_templates/${versionDir} $TEMPLATE_LINK
      echo Linked $TEMPLATE_LINK
  fi
''
