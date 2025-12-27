# Camera and Replay options
{lib, ...}:
with lib; {
  clipToField = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Clip camera to field in replays";
  };

  goalReplayPOV = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Use POV goal replays";
  };

  goalReplayTimeout = mkOption {
    type = types.nullOr types.float;
    default = null;
    description = "How long to wait before switching to another player after a hit";
  };
}
