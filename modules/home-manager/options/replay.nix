# Replay and Recording options
{lib, ...}:
with lib; {
  autoUploadBallchasing = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Upload replays to ballchasing.com automatically";
  };

  autoUploadBallchasingAuthKey = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Auth token for ballchasing.com";
  };

  autoUploadBallchasingVisibility = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Replay visibility on ballchasing.com (public/unlisted/private)";
  };

  autoUploadCalculated = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Upload replays to calculated.gg automatically";
  };

  autoUploadCalculatedVisibility = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Replay visibility on calculated.gg";
  };

  autoUploadNotifications = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Show notifications on successful uploads";
  };

  autoUploadSave = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Save all replay files to export filepath";
  };

  autoUploadFilepath = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Path to export replays to";
  };

  nameTemplate = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Template for replay filename";
  };

  recordFPS = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "FPS to record replays at";
  };

  demoAutoSave = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Autosave last X demos (0 to disable)";
  };

  demoNameplates = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Show nameplates in demos";
  };
}
