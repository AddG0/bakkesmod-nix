# Loadout and Cosmetics options
{lib, ...}:
with lib; {
  colorEnabled = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Override car colors";
  };

  colorSame = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Use same car color for both teams";
  };

  bluePrimary = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Primary RGB values for blue car (e.g., '0.08 0.10 0.90 -1')";
  };

  blueSecondary = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Secondary RGB values for blue car";
  };

  orangePrimary = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Primary RGB values for orange car";
  };

  orangeSecondary = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Secondary RGB values for orange car";
  };

  alphBoost = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Wear alpha boost";
  };

  itemModEnabled = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable item mod";
  };

  itemModCode = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Current loadout code for item mod";
  };
}
