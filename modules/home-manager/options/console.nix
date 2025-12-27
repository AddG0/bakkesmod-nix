# Console options
{lib, ...}:
with lib; {
  enabled = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Show the console";
  };

  toggleable = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Allow console to be toggled (when false, disables console altogether)";
  };

  key = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Key to toggle the console (e.g., 'Tilde', 'F3')";
  };

  bufferSize = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Maximum amount of messages to store in console log";
  };

  suggestions = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Maximum amount of suggestions to show";
  };

  logKeys = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Log keypresses into the console";
  };

  height = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Height of the console window";
  };

  width = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Width of the console window";
  };

  x = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "X position of the console window";
  };

  y = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Y position of the console window";
  };
}
