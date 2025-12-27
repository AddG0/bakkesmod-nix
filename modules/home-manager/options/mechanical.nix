# Mechanical Limits options
{lib, ...}:
with lib; {
  enabled = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable/disable mechanical steer functionality";
  };

  steerLimit = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Clamp steering input";
  };

  throttleLimit = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Clamp throttle input";
  };

  pitchLimit = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Clamp pitch input";
  };

  yawLimit = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Clamp yaw input";
  };

  rollLimit = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Clamp roll input";
  };

  disableJump = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Disable jump";
  };

  disableBoost = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Disable boost";
  };

  disableHandbrake = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Disable handbrake";
  };

  holdBoost = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Hold boost automatically";
  };

  holdRoll = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Hold air roll automatically";
  };
}
