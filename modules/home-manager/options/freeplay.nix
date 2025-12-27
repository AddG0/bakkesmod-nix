# Freeplay options
{lib, ...}:
with lib; {
  enableGoal = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable goal scoring in freeplay";
  };

  enableGoalBakkesmod = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Use BakkesMod version of enabling goals";
  };

  goalSpeed = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Show speed at which goals are scored";
  };

  bindings = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable BakkesMod freeplay bindings";
  };

  limitBoostDefault = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Limit boost in freeplay when loaded";
  };

  carColor = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable normal car colors in freeplay";
  };

  stadiumColors = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable stadium colors in freeplay";
  };

  unlimitedFlips = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Allow unlimited flips in the air for practice";
  };
}
