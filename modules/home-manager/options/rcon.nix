# RCON options
{lib, ...}:
with lib; {
  enabled = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable the RCON plugin";
  };

  port = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "RCON server port";
  };

  password = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "RCON password";
  };

  timeout = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "RCON timeout in seconds";
  };

  log = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Log all incoming RCON commands";
  };
}
