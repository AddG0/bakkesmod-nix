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
  
  # Generate config content from options
  generateConfigContent = cfg: let
    c = cfg.config;
    lines = [
      # GUI Settings
      (formatConfigLine "bakkesmod_style_alpha" c.gui.alpha)
      (formatConfigLine "bakkesmod_style_light" c.gui.lightMode)
      (formatConfigLine "bakkesmod_style_scale" c.gui.scale)
      (formatConfigLine "bakkesmod_style_theme" c.gui.theme)
      (formatConfigLine "gui_quicksettings_rows" c.gui.quickSettingsRows)

      # Console Settings
      (formatConfigLine "cl_console_enabled" c.console.enabled)
      (formatConfigLine "cl_console_toggleable" c.console.toggleable)
      (formatConfigLine "cl_console_key" c.console.key)
      (formatConfigLine "cl_console_buffersize" c.console.bufferSize)
      (formatConfigLine "cl_console_suggestions" c.console.suggestions)
      (formatConfigLine "cl_console_logkeys" c.console.logKeys)
      (formatConfigLine "cl_console_height" c.console.height)
      (formatConfigLine "cl_console_width" c.console.width)
      (formatConfigLine "cl_console_x" c.console.x)
      (formatConfigLine "cl_console_y" c.console.y)

      # Ranked Settings
      (formatConfigLine "ranked_showranks" c.ranked.showRanks)
      (formatConfigLine "ranked_showranks_casual" c.ranked.showRanksCasual)
      (formatConfigLine "ranked_showranks_casual_menu" c.ranked.showRanksCasualMenu)
      (formatConfigLine "ranked_showranks_menu" c.ranked.showRanksMenu)
      (formatConfigLine "ranked_showranks_gameover" c.ranked.showRanksGameOver)
      (formatConfigLine "ranked_disableranks" c.ranked.disableRanks)
      (formatConfigLine "ranked_disregardplacements" c.ranked.disregardPlacements)
      (formatConfigLine "ranked_aprilfools" c.ranked.aprilFools)
      (formatConfigLine "ranked_autogg" c.ranked.autoGG)
      (formatConfigLine "ranked_autogg_delay" c.ranked.autoGGDelay)
      (formatConfigLine "ranked_autogg_id" c.ranked.autoGGId)
      (formatConfigLine "ranked_autoqueue" c.ranked.autoQueue)
      (formatConfigLine "ranked_autosavereplay" c.ranked.autoSaveReplay)
      (formatConfigLine "ranked_autosavereplay_all" c.ranked.autoSaveReplayAll)

      # Replay Settings
      (formatConfigLine "cl_autoreplayupload_ballchasing" c.replay.autoUploadBallchasing)
      (formatConfigLine "cl_autoreplayupload_ballchasing_authkey" c.replay.autoUploadBallchasingAuthKey)
      (formatConfigLine "cl_autoreplayupload_ballchasing_visibility" c.replay.autoUploadBallchasingVisibility)
      (formatConfigLine "cl_autoreplayupload_calculated" c.replay.autoUploadCalculated)
      (formatConfigLine "cl_autoreplayupload_calculated_visibility" c.replay.autoUploadCalculatedVisibility)
      (formatConfigLine "cl_autoreplayupload_notifications" c.replay.autoUploadNotifications)
      (formatConfigLine "cl_autoreplayupload_save" c.replay.autoUploadSave)
      (formatConfigLine "cl_autoreplayupload_filepath" c.replay.autoUploadFilepath)
      (formatConfigLine "cl_autoreplayupload_replaynametemplate" c.replay.nameTemplate)
      (formatConfigLine "cl_record_fps" c.replay.recordFPS)
      (formatConfigLine "cl_demo_autosave" c.replay.demoAutoSave)
      (formatConfigLine "cl_demo_nameplates" c.replay.demoNameplates)

      # Freeplay Settings
      (formatConfigLine "sv_freeplay_enablegoal" c.freeplay.enableGoal)
      (formatConfigLine "sv_freeplay_enablegoal_bakkesmod" c.freeplay.enableGoalBakkesmod)
      (formatConfigLine "sv_freeplay_goalspeed" c.freeplay.goalSpeed)
      (formatConfigLine "sv_freeplay_bindings" c.freeplay.bindings)
      (formatConfigLine "sv_freeplay_limitboost_default" c.freeplay.limitBoostDefault)
      (formatConfigLine "cl_freeplay_carcolor" c.freeplay.carColor)
      (formatConfigLine "cl_freeplay_stadiumcolors" c.freeplay.stadiumColors)
      (formatConfigLine "sv_soccar_unlimitedflips" c.freeplay.unlimitedFlips)

      # Training Settings
      (formatConfigLine "sv_training_enabled" c.training.enabled)
      (formatConfigLine "sv_training_allowmirror" c.training.allowMirror)
      (formatConfigLine "sv_training_autoshuffle" c.training.autoShuffle)
      (formatConfigLine "sv_training_clock" c.training.clock)
      (formatConfigLine "sv_training_timeup_reset" c.training.timeupReset)
      (formatConfigLine "sv_training_limitboost" c.training.limitBoost)
      (formatConfigLine "sv_training_player_velocity" c.training.playerVelocity)
      (formatConfigLine "sv_training_usefreeplaymap" c.training.useFreeplayMap)
      (formatConfigLine "sv_training_userandommap" c.training.useRandomMap)
      (formatConfigLine "sv_training_var_loc" c.training.varLocation)
      (formatConfigLine "sv_training_var_loc_z" c.training.varLocationZ)
      (formatConfigLine "sv_training_var_rot" c.training.varRotation)
      (formatConfigLine "sv_training_var_speed" c.training.varSpeed)
      (formatConfigLine "sv_training_var_spin" c.training.varSpin)
      (formatConfigLine "sv_training_var_car_loc" c.training.varCarLocation)
      (formatConfigLine "sv_training_var_car_rot" c.training.varCarRotation)
      (formatConfigLine "sv_training_goalblocker_enabled" c.training.goalBlockerEnabled)
      (formatConfigLine "cl_training_printjson" c.training.printJson)

      # Anonymizer Settings
      (formatConfigLine "cl_anonymizer_mode_team" c.anonymizer.modeTeam)
      (formatConfigLine "cl_anonymizer_mode_party" c.anonymizer.modeParty)
      (formatConfigLine "cl_anonymizer_mode_opponent" c.anonymizer.modeOpponent)
      (formatConfigLine "cl_anonymizer_alwaysshowcars" c.anonymizer.alwaysShowCars)
      (formatConfigLine "cl_anonymizer_bot" c.anonymizer.bot)
      (formatConfigLine "cl_anonymizer_scores" c.anonymizer.scores)
      (formatConfigLine "cl_anonymizer_hideforfeit" c.anonymizer.hideForfeit)
      (formatConfigLine "cl_anonymizer_kickoff_quickchat" c.anonymizer.kickoffQuickchat)

      # Loadout Settings
      (formatConfigLine "cl_loadout_color_enabled" c.loadout.colorEnabled)
      (formatConfigLine "cl_loadout_color_same" c.loadout.colorSame)
      (formatConfigLine "cl_loadout_blue_primary" c.loadout.bluePrimary)
      (formatConfigLine "cl_loadout_blue_secondary" c.loadout.blueSecondary)
      (formatConfigLine "cl_loadout_orange_primary" c.loadout.orangePrimary)
      (formatConfigLine "cl_loadout_orange_secondary" c.loadout.orangeSecondary)
      (formatConfigLine "cl_alphaboost" c.loadout.alphBoost)
      (formatConfigLine "cl_itemmod_enabled" c.loadout.itemModEnabled)
      (formatConfigLine "cl_itemmod_code" c.loadout.itemModCode)

      # Camera Settings
      (formatConfigLine "cl_camera_cliptofield" c.camera.clipToField)
      (formatConfigLine "cl_goalreplay_pov" c.camera.goalReplayPOV)
      (formatConfigLine "cl_goalreplay_timeout" c.camera.goalReplayTimeout)

      # DollyCam Settings
      (formatConfigLine "dolly_render" c.dollyCam.render)
      (formatConfigLine "dolly_render_frame" c.dollyCam.renderFrame)
      (formatConfigLine "dolly_interpmode" c.dollyCam.interpMode)
      (formatConfigLine "dolly_interpmode_location" c.dollyCam.interpModeLocation)
      (formatConfigLine "dolly_interpmode_rotation" c.dollyCam.interpModeRotation)
      (formatConfigLine "dolly_chaikin_degree" c.dollyCam.chaikinDegree)
      (formatConfigLine "dolly_spline_acc" c.dollyCam.splineAcc)
      (formatConfigLine "dolly_path_directory" c.dollyCam.pathDirectory)

      # Mechanical Settings
      (formatConfigLine "mech_enabled" c.mechanical.enabled)
      (formatConfigLine "mech_steer_limit" c.mechanical.steerLimit)
      (formatConfigLine "mech_throttle_limit" c.mechanical.throttleLimit)
      (formatConfigLine "mech_pitch_limit" c.mechanical.pitchLimit)
      (formatConfigLine "mech_yaw_limit" c.mechanical.yawLimit)
      (formatConfigLine "mech_roll_limit" c.mechanical.rollLimit)
      (formatConfigLine "mech_disable_jump" c.mechanical.disableJump)
      (formatConfigLine "mech_disable_boost" c.mechanical.disableBoost)
      (formatConfigLine "mech_disable_handbrake" c.mechanical.disableHandbrake)
      (formatConfigLine "mech_hold_boost" c.mechanical.holdBoost)
      (formatConfigLine "mech_hold_roll" c.mechanical.holdRoll)

      # RCON Settings
      (formatConfigLine "rcon_enabled" c.rcon.enabled)
      (formatConfigLine "rcon_port" c.rcon.port)
      (formatConfigLine "rcon_password" c.rcon.password)
      (formatConfigLine "rcon_timeout" c.rcon.timeout)
      (formatConfigLine "rcon_log" c.rcon.log)

      # Misc Settings
      (formatConfigLine "cl_draw_fpsonboot" c.misc.drawFPSOnBoot)
      (formatConfigLine "cl_draw_systemtime" c.misc.drawSystemTime)
      (formatConfigLine "cl_draw_systemtime_format" c.misc.systemTimeFormat)
      (formatConfigLine "cl_online_status_detailed" c.misc.onlineStatusDetailed)
      (formatConfigLine "cl_soccar_ballfadein" c.misc.ballFadeIn)
      (formatConfigLine "cl_soccar_boostcounter" c.misc.boostCounter)
      (formatConfigLine "cl_soccar_jumphelp" c.misc.jumpHelp)
      (formatConfigLine "cl_soccar_jumphelp_carcolor" c.misc.jumpHelpCarColor)
      (formatConfigLine "cl_workshop_freecam" c.misc.workshopFreecam)
      (formatConfigLine "cl_mainmenu_background" c.misc.mainMenuBackground)
      (formatConfigLine "cl_misophoniamode_enabled" c.misc.misophoniaModeEnabled)
      (formatConfigLine "cl_notifications_enabled_beta" c.misc.notificationsEnabledBeta)
      (formatConfigLine "cl_notifications_ranked" c.misc.notificationsRanked)
      (formatConfigLine "cl_rendering_disabled" c.misc.renderingDisabled)
      (formatConfigLine "cl_rendering_scaleform_disabled" c.misc.scaleformDisabled)
      (formatConfigLine "sv_soccar_goalslomo" c.misc.goalSlomo)
      (formatConfigLine "alliteration_andy" c.misc.alliterationAndy)
      (formatConfigLine "bakkesmod_log_instantflush" c.misc.logInstantFlush)
      (formatConfigLine "inputbuffer_reset_automatic" c.misc.inputBufferResetAutomatic)

      # Queue Menu Settings
      (formatConfigLine "queuemenu_close_joining" c.queueMenu.closeJoining)
      (formatConfigLine "queuemenu_open_mainmenu" c.queueMenu.openMainMenu)
      (formatConfigLine "queuemenu_open_match_ended" c.queueMenu.openMatchEnded)

      # Plugin Favorites
      (formatConfigLine "cl_settings_plugin_favorites" c.pluginFavorites)
    ]
    # Extra config - arbitrary cvars
    ++ (mapAttrsToList (name: value: formatConfigLine name value) c.extraConfig);
  in
    concatStringsSep "\n" (filter (l: l != "") lines);
}
