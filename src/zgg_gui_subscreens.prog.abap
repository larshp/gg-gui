REPORT zgg_gui_subscreens.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_right_screen TYPE sy-dynnr VALUE '0120'.
DATA gv_left_value TYPE c LENGTH 30 VALUE 'Shared left value'.
DATA gv_right_a TYPE c LENGTH 30 VALUE 'Details variant A'.
DATA gv_right_b TYPE c LENGTH 30 VALUE 'Details variant B'.
DATA gv_summary TYPE c LENGTH 70.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF gv_right_screen = '0120'.
    gv_summary = |Parent sees: { gv_left_value } / { gv_right_a }|.
  ELSE.
    gv_summary = |Parent sees: { gv_left_value } / { gv_right_b }|.
  ENDIF.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.

  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_ok_code.
    WHEN 'SWAP'.
      IF gv_right_screen = '0120'.
        gv_right_screen = '0130'.
      ELSE.
        gv_right_screen = '0120'.
      ENDIF.
    WHEN 'RESET'.
      gv_left_value = 'Shared left value'.
      gv_right_a = 'Details variant A'.
      gv_right_b = 'Details variant B'.
      gv_right_screen = '0120'.
    WHEN 'APPLY'.
      MESSAGE 'Parent and both active subscreens completed PAI' TYPE 'S'.
  ENDCASE.
ENDMODULE.

MODULE validate_left INPUT.
  IF gv_left_value IS INITIAL.
    MESSAGE 'The static subscreen value is required' TYPE 'E'.
  ENDIF.
ENDMODULE.

MODULE validate_right_a INPUT.
  IF gv_right_a IS INITIAL.
    MESSAGE 'Variant A requires a value' TYPE 'E'.
  ENDIF.
ENDMODULE.

MODULE validate_right_b INPUT.
  IF gv_right_b IS INITIAL.
    MESSAGE 'Variant B requires a value' TYPE 'E'.
  ENDIF.
ENDMODULE.
