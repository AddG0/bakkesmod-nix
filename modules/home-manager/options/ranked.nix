# Ranked and MMR Display options
{lib, ...}:
with lib; {
  showRanks = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Show opponent ranks in ranked matches";
  };

  showRanksCasual = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Show player ranks in casual modes";
  };

  showRanksCasualMenu = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Show casual MMR in the queue menu";
  };

  showRanksMenu = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Show player ranks in the queue menu";
  };

  showRanksGameOver = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Only show opponent ranks when game is over";
  };

  disableRanks = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Disable rank display entirely";
  };

  disregardPlacements = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Don't take placement matches into account when calculating MMR";
  };

  aprilFools = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Enable april fools rank mode";
  };

  autoGG = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Automatically say GG at the end of the match";
  };

  autoGGDelay = mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Time range to wait before sending GG (e.g., '(250, 2500)')";
  };

  autoGGId = mkOption {
    type = types.nullOr types.int;
    default = null;
    description = "GG message ID 0-3 (order in post-game quickchats)";
  };

  autoQueue = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Automatically queue on match end";
  };

  autoSaveReplay = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Automatically save ranked replay at end of match";
  };

  autoSaveReplayAll = mkOption {
    type = types.nullOr types.bool;
    default = null;
    description = "Automatically save replay at end of all matches";
  };
}
