PROCESS BEFORE OUTPUT.
  MODULE status_0100.
  CALL SUBSCREEN left_area INCLUDING sy-repid '0110'.
  CALL SUBSCREEN right_area INCLUDING sy-repid gv_right_screen.

PROCESS AFTER INPUT.
  MODULE exit_0100 AT EXIT-COMMAND.
  CALL SUBSCREEN left_area.
  CALL SUBSCREEN right_area.
  MODULE user_command_0100.
