# Behavior test for option -> cvar generation. A wrong cvar name yields a valid
# config file that silently does nothing, so these pin the names, not just the
# mechanism.
{
  pkgs,
  src,
}: let
  inherit (pkgs) lib;

  configLib = import "${src}/modules/home-manager/lib/config.nix" {inherit lib;};

  # Runs the real module, so a renamed option breaks this too.
  generate = settings:
    configLib.generateConfigContent
    (lib.evalModules {
      modules = [
        (import "${src}/modules/home-manager")
        {
          options.home.packages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [];
          };

          config._module.args.pkgs = pkgs;
          config.programs.bakkesmod = {
            enable = true;
            package = pkgs.callPackage "${src}/pkgs/bakkesmod.nix" {};
            config = settings;
          };
        }
      ];
    })
    .config
    .programs
    .bakkesmod;

  emits = behavior: settings: expected: {
    inherit behavior expected;
    actual = generate settings;
  };

  cases = [
    (emits "declares nothing when nothing is set" {} "")

    (emits "writes a float with the cvar BakkesMod reads it from"
      {gui.scale = 1.5;} ''bakkesmod_style_scale "1.500000"'')

    (emits "writes an int without decimals"
      {console.height = 300;} ''cl_console_height "300"'')

    (emits "writes true as 1"
      {ranked.showRanks = true;} ''ranked_showranks "1"'')

    # Omitting it instead would leave the player's existing setting standing.
    (emits "writes false as 0 rather than omitting it"
      {console.enabled = false;} ''cl_console_enabled "0"'')

    (emits "writes a string as-is"
      {gui.theme = "visibility.json";} ''bakkesmod_style_theme "visibility.json"'')

    (emits "escapes quotes and backslashes so the cvar cannot be broken out of"
      {misc.systemTimeFormat = ''a"b\c'';}
      ''cl_draw_systemtime_format "a\"b\\c"'')

    (emits "passes an arbitrary cvar through extraConfig"
      {extraConfig."cl_dejavu_enabled" = true;} ''cl_dejavu_enabled "1"'')

    (emits "emits only the option that was set"
      {gui.lightMode = true;} ''bakkesmod_style_light "1"'')
  ];

  failures = lib.filter (c: c.actual != c.expected) cases;

  report = c: ''
    ${c.behavior}
      expected: ${builtins.toJSON c.expected}
      actual:   ${builtins.toJSON c.actual}'';
in
  if failures == []
  then
    pkgs.runCommand "config-generation-test" {} ''
      ${lib.concatMapStringsSep "\n" (c: "echo ${lib.escapeShellArg c.behavior}") cases}
      touch $out
    ''
  else
    throw ''
      config generation produced the wrong cvars:

      ${lib.concatMapStringsSep "\n\n" report failures}''
