# Queue Menu options
{lib, ...}:
with lib; {
  closeJoining = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Automatically close queue menu when joining match";
  };

  openMainMenu = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Automatically open queue menu when entering main menu";
  };

  openMatchEnded = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Automatically open queue menu on match end";
  };
}
