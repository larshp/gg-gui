PROCESS BEFORE OUTPUT.
  MODULE status_0100.

PROCESS AFTER INPUT.
  MODULE exit_0100 AT EXIT-COMMAND.
  FIELD gv_first MODULE validate_first ON REQUEST.
  FIELD gv_request MODULE observe_request ON INPUT.
  CHAIN.
    FIELD gv_first.
    FIELD gv_last.
    MODULE validate_name ON CHAIN-REQUEST.
  ENDCHAIN.
  MODULE user_command_0100.
