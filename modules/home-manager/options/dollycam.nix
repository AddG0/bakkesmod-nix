# DollyCam options
{lib, ...}:
with lib; {
  render = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Render the current camera path";
  };

  renderFrame = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Render frame numbers on the path";
  };

  interpMode = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Interpolation mode to use";
  };

  interpModeLocation = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Interpolation mode for location";
  };

  interpModeRotation = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Interpolation mode for rotation";
  };

  chaikinDegree = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Amount of times to apply Chaikin smoothing to the spline";
  };

  splineAcc = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Spline interpolation time accuracy";
  };

  pathDirectory = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Location for saving and loading paths";
  };
}
