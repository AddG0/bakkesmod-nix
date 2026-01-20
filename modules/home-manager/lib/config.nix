# Generates BakkesMod cfg file content from Home Manager options
{lib, ...}:
with lib; rec {
  boolToStr = b:
    if b
    then "1"
    else "0";

  # Escape special characters in strings for BakkesMod config
  escapeConfigString = s:
    builtins.replaceStrings
      ["\"" "\\" "\n" "\r" "\t"]
      ["\\\"" "\\\\" "\\n" "\\r" "\\t"]
      s;

  # Format a config line with proper escaping
  formatConfigLine = key: value:
    if value == null
    then ""
    else if builtins.isBool value
    then "${key} \"${boolToStr value}\""
    else if builtins.isInt value
    then "${key} \"${toString value}\""
    else if builtins.isFloat value
    then "${key} \"${toString value}\""
    else "${key} \"${escapeConfigString value}\"";

  # Mapping from BakkesMod cvar names to config option accessors
  configMapping = c: {
    # GUI Settings
    "bakkesmod_style_alpha" = c.gui.alpha;
    "bakkesmod_style_light" = c.gui.lightMode;
    "bakkesmod_style_scale" = c.gui.scale;
    "bakkesmod_style_theme" = c.gui.theme;
    "gui_quicksettings_rows" = c.gui.quickSettingsRows;

    # Console Settings
    "cl_console_buffersize" = c.console.bufferSize;
    "cl_console_enabled" = c.console.enabled;
    "cl_console_height" = c.console.height;
    "cl_console_key" = c.console.key;
    "cl_console_logkeys" = c.console.logKeys;
    "cl_console_suggestions" = c.console.suggestions;
    "cl_console_toggleable" = c.console.toggleable;
    "cl_console_width" = c.console.width;
    "cl_console_x" = c.console.x;
    "cl_console_y" = c.console.y;

    # Ranked Settings
    "ranked_aprilfools" = c.ranked.aprilFools;
    "ranked_autogg" = c.ranked.autoGG;
    "ranked_autogg_delay" = c.ranked.autoGGDelay;
    "ranked_autogg_id" = c.ranked.autoGGId;
    "ranked_autoqueue" = c.ranked.autoQueue;
    "ranked_autosavereplay" = c.ranked.autoSaveReplay;
    "ranked_autosavereplay_all" = c.ranked.autoSaveReplayAll;
    "ranked_disableranks" = c.ranked.disableRanks;
    "ranked_disregardplacements" = c.ranked.disregardPlacements;
    "ranked_showranks" = c.ranked.showRanks;
    "ranked_showranks_casual" = c.ranked.showRanksCasual;
    "ranked_showranks_casual_menu" = c.ranked.showRanksCasualMenu;
    "ranked_showranks_gameover" = c.ranked.showRanksGameOver;
    "ranked_showranks_menu" = c.ranked.showRanksMenu;

    # Replay Settings
    "cl_autoreplayupload_ballchasing" = c.replay.autoUploadBallchasing;
    "cl_autoreplayupload_ballchasing_authkey" = c.replay.autoUploadBallchasingAuthKey;
    "cl_autoreplayupload_ballchasing_visibility" = c.replay.autoUploadBallchasingVisibility;
    "cl_autoreplayupload_calculated" = c.replay.autoUploadCalculated;
    "cl_autoreplayupload_calculated_visibility" = c.replay.autoUploadCalculatedVisibility;
    "cl_autoreplayupload_filepath" = c.replay.autoUploadFilepath;
    "cl_autoreplayupload_notifications" = c.replay.autoUploadNotifications;
    "cl_autoreplayupload_replaynametemplate" = c.replay.nameTemplate;
    "cl_autoreplayupload_save" = c.replay.autoUploadSave;
    "cl_demo_autosave" = c.replay.demoAutoSave;
    "cl_demo_nameplates" = c.replay.demoNameplates;
    "cl_record_fps" = c.replay.recordFPS;

    # Freeplay Settings
    "cl_freeplay_carcolor" = c.freeplay.carColor;
    "cl_freeplay_stadiumcolors" = c.freeplay.stadiumColors;
    "sv_freeplay_bindings" = c.freeplay.bindings;
    "sv_freeplay_enablegoal" = c.freeplay.enableGoal;
    "sv_freeplay_enablegoal_bakkesmod" = c.freeplay.enableGoalBakkesmod;
    "sv_freeplay_goalspeed" = c.freeplay.goalSpeed;
    "sv_freeplay_limitboost_default" = c.freeplay.limitBoostDefault;
    "sv_soccar_unlimitedflips" = c.freeplay.unlimitedFlips;

    # Training Settings
    "cl_training_printjson" = c.training.printJson;
    "sv_training_allowmirror" = c.training.allowMirror;
    "sv_training_autoshuffle" = c.training.autoShuffle;
    "sv_training_clock" = c.training.clock;
    "sv_training_enabled" = c.training.enabled;
    "sv_training_goalblocker_enabled" = c.training.goalBlockerEnabled;
    "sv_training_limitboost" = c.training.limitBoost;
    "sv_training_player_velocity" = c.training.playerVelocity;
    "sv_training_timeup_reset" = c.training.timeupReset;
    "sv_training_usefreeplaymap" = c.training.useFreeplayMap;
    "sv_training_userandommap" = c.training.useRandomMap;
    "sv_training_var_car_loc" = c.training.varCarLocation;
    "sv_training_var_car_rot" = c.training.varCarRotation;
    "sv_training_var_loc" = c.training.varLocation;
    "sv_training_var_loc_z" = c.training.varLocationZ;
    "sv_training_var_rot" = c.training.varRotation;
    "sv_training_var_speed" = c.training.varSpeed;
    "sv_training_var_spin" = c.training.varSpin;

    # Anonymizer Settings
    "cl_anonymizer_alwaysshowcars" = c.anonymizer.alwaysShowCars;
    "cl_anonymizer_bot" = c.anonymizer.bot;
    "cl_anonymizer_hideforfeit" = c.anonymizer.hideForfeit;
    "cl_anonymizer_kickoff_quickchat" = c.anonymizer.kickoffQuickchat;
    "cl_anonymizer_mode_opponent" = c.anonymizer.modeOpponent;
    "cl_anonymizer_mode_party" = c.anonymizer.modeParty;
    "cl_anonymizer_mode_team" = c.anonymizer.modeTeam;
    "cl_anonymizer_scores" = c.anonymizer.scores;

    # Loadout Settings
    "cl_alphaboost" = c.loadout.alphBoost;
    "cl_itemmod_code" = c.loadout.itemModCode;
    "cl_itemmod_enabled" = c.loadout.itemModEnabled;
    "cl_loadout_blue_primary" = c.loadout.bluePrimary;
    "cl_loadout_blue_secondary" = c.loadout.blueSecondary;
    "cl_loadout_color_enabled" = c.loadout.colorEnabled;
    "cl_loadout_color_same" = c.loadout.colorSame;
    "cl_loadout_orange_primary" = c.loadout.orangePrimary;
    "cl_loadout_orange_secondary" = c.loadout.orangeSecondary;

    # Camera Settings
    "cl_camera_cliptofield" = c.camera.clipToField;
    "cl_goalreplay_pov" = c.camera.goalReplayPOV;
    "cl_goalreplay_timeout" = c.camera.goalReplayTimeout;

    # DollyCam Settings
    "dolly_chaikin_degree" = c.dollyCam.chaikinDegree;
    "dolly_interpmode" = c.dollyCam.interpMode;
    "dolly_interpmode_location" = c.dollyCam.interpModeLocation;
    "dolly_interpmode_rotation" = c.dollyCam.interpModeRotation;
    "dolly_path_directory" = c.dollyCam.pathDirectory;
    "dolly_render" = c.dollyCam.render;
    "dolly_render_frame" = c.dollyCam.renderFrame;
    "dolly_spline_acc" = c.dollyCam.splineAcc;

    # Mechanical Settings
    "mech_disable_boost" = c.mechanical.disableBoost;
    "mech_disable_handbrake" = c.mechanical.disableHandbrake;
    "mech_disable_jump" = c.mechanical.disableJump;
    "mech_enabled" = c.mechanical.enabled;
    "mech_hold_boost" = c.mechanical.holdBoost;
    "mech_hold_roll" = c.mechanical.holdRoll;
    "mech_pitch_limit" = c.mechanical.pitchLimit;
    "mech_roll_limit" = c.mechanical.rollLimit;
    "mech_steer_limit" = c.mechanical.steerLimit;
    "mech_throttle_limit" = c.mechanical.throttleLimit;
    "mech_yaw_limit" = c.mechanical.yawLimit;

    # RCON Settings
    "rcon_enabled" = c.rcon.enabled;
    "rcon_log" = c.rcon.log;
    "rcon_password" = c.rcon.password;
    "rcon_port" = c.rcon.port;
    "rcon_timeout" = c.rcon.timeout;

    # Misc Settings
    "alliteration_andy" = c.misc.alliterationAndy;
    "bakkesmod_log_instantflush" = c.misc.logInstantFlush;
    "cl_draw_fpsonboot" = c.misc.drawFPSOnBoot;
    "cl_draw_systemtime" = c.misc.drawSystemTime;
    "cl_draw_systemtime_format" = c.misc.systemTimeFormat;
    "cl_mainmenu_background" = c.misc.mainMenuBackground;
    "cl_misophoniamode_enabled" = c.misc.misophoniaModeEnabled;
    "cl_notifications_enabled_beta" = c.misc.notificationsEnabledBeta;
    "cl_notifications_ranked" = c.misc.notificationsRanked;
    "cl_online_status_detailed" = c.misc.onlineStatusDetailed;
    "cl_rendering_disabled" = c.misc.renderingDisabled;
    "cl_rendering_scaleform_disabled" = c.misc.scaleformDisabled;
    "cl_soccar_ballfadein" = c.misc.ballFadeIn;
    "cl_soccar_boostcounter" = c.misc.boostCounter;
    "cl_soccar_jumphelp" = c.misc.jumpHelp;
    "cl_soccar_jumphelp_carcolor" = c.misc.jumpHelpCarColor;
    "cl_workshop_freecam" = c.misc.workshopFreecam;
    "inputbuffer_reset_automatic" = c.misc.inputBufferResetAutomatic;
    "sv_soccar_goalslomo" = c.misc.goalSlomo;

    # Queue Menu Settings
    "queuemenu_close_joining" = c.queueMenu.closeJoining;
    "queuemenu_open_mainmenu" = c.queueMenu.openMainMenu;
    "queuemenu_open_match_ended" = c.queueMenu.openMatchEnded;

    # Plugin Favorites
    "cl_settings_plugin_favorites" = c.pluginFavorites;
  };

  # Generate config content from options
  generateConfigContent = cfg: let
    c = cfg.config;
    lines = mapAttrsToList formatConfigLine (configMapping c);
    extraLines = mapAttrsToList formatConfigLine c.extraConfig;
  in
    concatStringsSep "\n" (filter (l: l != "") (lines ++ extraLines));
}
