# GUI and Interface options
{lib, ...}:
with lib; {
  alpha = mkOption {
    type = types.nullOr types.float;
    default = null;
    description = "Alpha transparency for BakkesMod GUI (0.0-1.0)";
  };

  lightMode = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable light mode for GUI";
  };

  scale = mkOption {
    type = types.nullOr types.float;
    default = null;
    description = "GUI scaling factor";
  };

  theme = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Theme file to use (e.g., 'visibility.json')";
  };

  quickSettingsRows = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Maximum rows to display in quicksettings";
  };
}
