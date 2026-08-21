PROCESS BEFORE OUTPUT.
  MODULE status_0100.
  LOOP AT gt_rows INTO gs_row WITH CONTROL tc_rows
    CURSOR tc_rows-current_line.
    MODULE row_attributes.
  ENDLOOP.
  MODULE restore_cursor.

PROCESS AFTER INPUT.
  MODULE exit_0100 AT EXIT-COMMAND.
  LOOP AT gt_rows.
    CHAIN.
      FIELD gs_row-name.
      FIELD gs_row-quantity.
      FIELD gs_row-price.
      MODULE validate_row ON CHAIN-REQUEST.
    ENDCHAIN.
    MODULE update_row.
  ENDLOOP.
  MODULE user_command_0100.
