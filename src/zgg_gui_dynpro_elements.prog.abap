REPORT zgg_gui_dynpro_elements.

" Screen 0100 is a compact gallery of common Screen Painter elements.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_text TYPE c LENGTH 30 VALUE 'Editable text'.
DATA gv_output TYPE c LENGTH 40 VALUE 'Press Apply to refresh this value'.
DATA gv_secret TYPE c LENGTH 12 VALUE 'hidden'.
DATA gv_date TYPE d VALUE sy-datum.
DATA gv_time TYPE t VALUE sy-uzeit.
DATA gv_count TYPE i VALUE 5.
DATA gv_amount TYPE p LENGTH 8 DECIMALS 2 VALUE '12.50'.
DATA gv_list TYPE c LENGTH 10 VALUE 'ONE'.
DATA gv_check TYPE abap_bool VALUE abap_true.
DATA gv_radio_a TYPE abap_bool VALUE abap_true.
DATA gv_radio_b TYPE abap_bool.
DATA gv_pbo_count TYPE i.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  DATA lt_values TYPE vrm_values.

  ADD 1 TO gv_pbo_count.
  lt_values = VALUE #(
    ( key = 'ONE' text = 'First entry' )
    ( key = 'TWO' text = 'Second entry' )
    ( key = 'THREE' text = 'Third entry' ) ).

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'GV_LIST'
      values = lt_values.
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
    WHEN 'APPLY'.
      gv_output = |Applied { gv_list }, PBO pass { gv_pbo_count }|.
    WHEN 'RESET'.
      gv_text = 'Editable text'.
      gv_output = 'Values reset'.
      gv_secret = 'hidden'.
      gv_date = sy-datum.
      gv_time = sy-uzeit.
      gv_count = 5.
      gv_amount = '12.50'.
      gv_list = 'ONE'.
      gv_check = abap_true.
      gv_radio_a = abap_true.
      CLEAR gv_radio_b.
  ENDCASE.
ENDMODULE.
