REPORT zgg_gui_dynpro_flow.

" Screen 0100 exposes the order and effects of dynpro flow-logic statements.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_first TYPE c LENGTH 20 VALUE 'Ada'.
DATA gv_last TYPE c LENGTH 20 VALUE 'Lovelace'.
DATA gv_request TYPE c LENGTH 20.
DATA gv_dynamic TYPE c LENGTH 30 VALUE 'Dynamically controlled'.
DATA gv_enable TYPE abap_bool VALUE abap_true.
DATA gv_cursor_field TYPE c LENGTH 30 VALUE 'No cursor read yet'.
DATA gv_cursor_line TYPE i.
DATA gv_focus_first TYPE abap_bool.
DATA gv_log1 TYPE c LENGTH 55.
DATA gv_log2 TYPE c LENGTH 55.
DATA gv_log3 TYPE c LENGTH 55.
DATA gv_log4 TYPE c LENGTH 55.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM add_log USING 'PBO: STATUS_0100'.

  LOOP AT SCREEN.
    IF screen-group1 = 'DYN'.
      screen-input = gv_enable.
      IF gv_enable = abap_true.
        screen-invisible = 0.
      ELSE.
        screen-invisible = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

  IF gv_focus_first = abap_true.
    SET CURSOR FIELD 'GV_FIRST'.
    CLEAR gv_focus_first.
  ENDIF.
ENDMODULE.

MODULE validate_first INPUT.
  PERFORM add_log USING 'PAI: VALIDATE_FIRST ON REQUEST'.
  IF gv_first IS INITIAL.
    MESSAGE 'Enter a first name' TYPE 'E'.
  ENDIF.
ENDMODULE.

MODULE observe_request INPUT.
  PERFORM add_log USING 'PAI: OBSERVE_REQUEST ON INPUT'.
ENDMODULE.

MODULE validate_name INPUT.
  PERFORM add_log USING 'PAI: VALIDATE_NAME ON CHAIN-REQUEST'.
  IF gv_first = gv_last AND gv_first IS NOT INITIAL.
    MESSAGE 'First and last name must differ in this demonstration' TYPE 'E'.
  ENDIF.
ENDMODULE.

MODULE exit_0100 INPUT.
  DATA lv_exit_code TYPE sy-ucomm.

  lv_exit_code = gv_ok_code.
  CLEAR gv_ok_code.
  IF lv_exit_code = 'CANCEL'.
    MESSAGE 'Changes canceled' TYPE 'S'.
  ENDIF.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.

  PERFORM add_log USING 'PAI: USER_COMMAND_0100'.
  GET CURSOR FIELD gv_cursor_field LINE gv_cursor_line.

  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_ok_code.
    WHEN 'APPLY'.
      MESSAGE |Validated { gv_first } { gv_last }| TYPE 'S'.
    WHEN 'FOCUS'.
      gv_focus_first = abap_true.
    WHEN 'RESET'.
      gv_first = 'Ada'.
      gv_last = 'Lovelace'.
      CLEAR: gv_request, gv_dynamic, gv_log1, gv_log2, gv_log3, gv_log4.
      gv_dynamic = 'Dynamically controlled'.
      gv_enable = abap_true.
      gv_cursor_field = 'No cursor read yet'.
      CLEAR gv_cursor_line.
  ENDCASE.
ENDMODULE.

FORM add_log USING iv_text TYPE csequence.
  gv_log4 = gv_log3.
  gv_log3 = gv_log2.
  gv_log2 = gv_log1.
  gv_log1 = |{ sy-uzeit TIME = USER }  { iv_text }|.
ENDFORM.
