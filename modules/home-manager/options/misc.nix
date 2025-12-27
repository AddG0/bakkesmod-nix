# Miscellaneous Client Settings
{lib, ...}:
with lib; {
  drawFPSOnBoot = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Draw FPS counter when game starts";
  };

  drawSystemTime = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Draw system time on screen";
  };

  systemTimeFormat = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Format string for system time (e.g., '%I:%M %p')";
  };

  onlineStatusDetailed = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Show detailed match info for friends (score & game time)";
  };

  ballFadeIn = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable ball fade in effect";
  };

  boostCounter = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Boost counts up instead of down";
  };

  jumpHelp = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Play sounds for jumping (0=off, 1=countdown, 2=elapsed, 3=both)";
  };

  jumpHelpCarColor = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Make car red/green based on jump availability";
  };

  workshopFreecam = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enter/exit spectator mode in custom maps";
  };

  mainMenuBackground = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Main menu background ID";
  };

  misophoniaModeEnabled = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Disable items with food sounds (e.g., donut goal explosion)";
  };

  notificationsEnabledBeta = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable BakkesMod notifications";
  };

  notificationsRanked = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Show MMR change popup after match";
  };

  renderingDisabled = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable/disable rendering entirely";
  };

  scaleformDisabled = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable/disable Scaleform rendering";
  };

  goalSlomo = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable/disable slow-motion after scoring";
  };

  alliterationAndy = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Give all players alliterated names (e.g., Stalling Steven)";
  };

  logInstantFlush = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Instantly write log to file";
  };

  inputBufferResetAutomatic = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Automatically reset input buffer after alt-tab";
  };
}
