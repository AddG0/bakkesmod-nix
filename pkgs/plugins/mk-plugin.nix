# mkPlugin - Builder for BakkesMod plugin packages
#
# Creates a derivation from a plugin zip downloaded from bakkesplugins.com CDN.
# Plugin metadata (URL, hash) comes from data/plugins.json for reproducible builds.
{
  lib,
  stdenv,
  unzip,
  fetchurl,
}: {
  pname,
  version ? "latest",
  pluginId,
  url,
  sha256,
  description ? "",
  meta ? {},
}: let
  # Normalize pname: "Deja Vu - Player Tracking" -> "deja-vu-player-tracking"
  safePname = let
    replaced = builtins.replaceStrings
      [" " "_" "'" "\"" "(" ")" "[" "]" "+" "&" "|" ";" "$" "`" "{" "}" "<" ">" "\\" "!" "?" "#" "@" "%" "^" "*" "=" "/" ":" "," "." "~"]
      ["-" "-" "" "" "" "" "" "" "-" "-" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ""]
      pname;
    collapseDashes = s:
      let s' = builtins.replaceStrings ["--"] ["-"] s;
      in if s == s' then s else collapseDashes s';
    collapsed = collapseDashes replaced;
    trimmed = lib.removePrefix "-" (lib.removeSuffix "-" collapsed);
  in
    lib.toLower trimmed;

  src = fetchurl {
    inherit url sha256;
    name = "bakkesmod-plugin-${pluginId}.zip";
  };
in
  stdenv.mkDerivation {
    pname = safePname;
    inherit version src;

    nativeBuildInputs = [unzip];
    sourceRoot = ".";

    unpackPhase = ''
      runHook preUnpack
      mkdir -p source

      # Validate archive before extraction
      if ! ${unzip}/bin/unzip -t $src >/dev/null 2>&1; then
        echo "ERROR: Corrupted zip file for ${pname} (ID: ${pluginId})" >&2
        exit 1
      fi

      if ! ${unzip}/bin/unzip -q $src -d source/; then
        echo "ERROR: Extraction failed for ${pname} (ID: ${pluginId})" >&2
        exit 1
      fi

      if [ ! "$(ls -A source/)" ]; then
        echo "ERROR: Empty archive for ${pname} (ID: ${pluginId})" >&2
        exit 1
      fi

      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/bakkesmod

      if [ ! "$(ls -A source/)" ]; then
        echo "ERROR: No files to install for ${pname}" >&2
        exit 1
      fi

      # Preserve plugin directory structure (plugins/, data/, etc.)
      cp -r source/* $out/share/bakkesmod/

      if ! find $out/share/bakkesmod -name "*.dll" 2>/dev/null | grep -q .; then
        echo "WARNING: No DLL found in ${pname} - plugin may not load" >&2
      fi

      # Remove Windows debug/build artifacts
      find $out/share/bakkesmod -type f \( -name "*.pdb" -o -name "*.exp" -o -name "*.lib" \) -delete 2>/dev/null || true

      runHook postInstall
    '';

    meta = with lib; {
      inherit description;
      homepage = "https://bakkesplugins.com/plugins/view/${pluginId}";
      license = licenses.unfree;
      platforms = platforms.linux;
    } // meta;
  }
