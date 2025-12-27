# Anonymizer options
{lib, ...}:
with lib; {
  modeTeam = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Anonymizer mode for team (0=off, 1=on)";
  };

  modeParty = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Anonymizer mode for party members (0=off, 1=on)";
  };

  modeOpponent = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "Anonymizer mode for opponents (0=off, 1=on)";
  };

  alwaysShowCars = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Never anonymize cars";
  };

  bot = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Use bot names for anonymization";
  };

  scores = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Hide scoreboard info";
  };

  hideForfeit = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Hide forfeit votes";
  };

  kickoffQuickchat = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Only turn on quickchat during 3,2,1 countdown";
  };
}
