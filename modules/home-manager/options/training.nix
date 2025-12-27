# Training Variance options
{lib, ...}:
with lib; {
  enabled = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable custom training variance";
  };

  allowMirror = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Mirror custom training shots randomly";
  };

  autoShuffle = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Automatically shuffle playlists";
  };

  clock = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Time limit for shots in seconds (0 for unlimited)";
  };

  timeupReset = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Reset shot instead of going to next when time is up";
  };

  limitBoost = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Limit boost in custom training (-1 for unlimited)";
  };

  playerVelocity = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Initial player velocity value";
  };

  useFreeplayMap = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Use the map you use in freeplay for custom training";
  };

  useRandomMap = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Use a random map for custom training";
  };

  varLocation = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Ball location variance in unreal units (e.g., '(-150, 150)')";
  };

  varLocationZ = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Ball Z location variance in unreal units (e.g., '(-20, 100)')";
  };

  varRotation = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Ball rotation variance in % (e.g., '(-2.5, 2.5)')";
  };

  varSpeed = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Ball velocity variance in % (e.g., '(-5, 5)')";
  };

  varSpin = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Ball spin variance in unreal units (e.g., '(-6, 6)')";
  };

  varCarLocation = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Car location variance in unreal units";
  };

  varCarRotation = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Car rotation variance in %";
  };

  goalBlockerEnabled = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable goal blocker in training";
  };

  printJson = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Print training JSON data";
  };
}
