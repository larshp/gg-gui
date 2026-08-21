PROCESS BEFORE OUTPUT.
  MODULE status_0200.
  CALL SUBSCREEN sub_identity INCLUDING sy-repid '0110'.
  CALL SUBSCREEN sub_settings INCLUDING sy-repid '0120'.
  CALL SUBSCREEN sub_advanced INCLUDING sy-repid '0130'.

PROCESS AFTER INPUT.
  MODULE exit_0100 AT EXIT-COMMAND.
  CALL SUBSCREEN sub_identity.
  CALL SUBSCREEN sub_settings.
  CALL SUBSCREEN sub_advanced.
  MODULE user_command_0200.
