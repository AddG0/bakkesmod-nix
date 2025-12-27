# BakkesMod plugin package set
#
# Generates derivations from data/plugins.json (run `nix run .#update` to refresh).
# Only plugins with valid URL and hash are exposed as packages.
{
  lib,
  callPackage,
}: let
  mkPlugin = callPackage ./mk-plugin.nix {};
  pluginsData = builtins.fromJSON (builtins.readFile ../../data/plugins.json);

  # Normalize: "Deja Vu - Player Tracking" -> "deja-vu-player-tracking"
  toAttrName = name: let
    replaced = builtins.replaceStrings
      [" " "_" "'" "\"" "(" ")" "[" "]" "+" "&" "!" "?" "#" "@" "$" "%" "^" "*" "=" "{" "}" "|" "\\" "/" ":" ";" "," "." "<" ">" "`" "~"]
      ["-" "-" "" "" "" "" "" "" "-" "-" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ""]
      name;
    collapseDashes = s:
      let s' = builtins.replaceStrings ["--"] ["-"] s;
      in if s == s' then s else collapseDashes s';
    collapsed = collapseDashes replaced;
    trimmed = lib.removePrefix "-" (lib.removeSuffix "-" collapsed);
  in
    lib.toLower trimmed;

  # Only include plugins that can be built reproducibly
  buildablePlugins = builtins.filter (p:
    (p.hash or "") != "" && (p.url or "") != ""
  ) pluginsData;

  pluginDerivations = builtins.listToAttrs (
    map (plugin: {
      name = toAttrName plugin.name;
      value = mkPlugin {
        pname = plugin.name;
        version = plugin.version;
        pluginId = toString plugin.id;
        url = plugin.url;
        sha256 = plugin.hash;
        description = plugin.description or "";
      };
    }) buildablePlugins
  );

  # Introspection for debugging/tooling
  metadata = {
    all = pluginsData;
    buildable = buildablePlugins;
    count = builtins.length pluginsData;
    buildableCount = builtins.length buildablePlugins;
  };
in
  pluginDerivations // {inherit metadata;}
