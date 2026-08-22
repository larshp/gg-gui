REPORT zgg_gui_dialogs_help.

TYPES ty_f4_value TYPE c LENGTH 20.
TYPES ty_f4_values TYPE STANDARD TABLE OF ty_f4_value WITH EMPTY KEY.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_choice TYPE c LENGTH 20 VALUE 'ALPHA'.
DATA gv_result TYPE c LENGTH 70 VALUE 'Choose an action or request F1/F4 on the field'.
DATA gv_dialog_text TYPE c LENGTH 40 VALUE 'Editable modal value'.
DATA gv_dialog_result TYPE c LENGTH 40.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.
  DATA lv_answer TYPE c LENGTH 1.
  DATA lt_fields TYPE STANDARD TABLE OF sval WITH EMPTY KEY.

  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_ok_code.
    WHEN 'DIALOG'.
      CLEAR gv_dialog_result.
      CALL SCREEN 200 STARTING AT 10 5 ENDING AT 70 12.
      IF gv_dialog_result IS NOT INITIAL.
        gv_result = |Modal dialog: { gv_dialog_result }|.
      ENDIF.
    WHEN 'CONFIRM'.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar      = 'Confirmation sample'
          text_question = 'Apply the current choice?'
          text_button_1 = 'Apply'
          text_button_2 = 'Cancel'
        IMPORTING
          answer        = lv_answer.
      IF lv_answer = '1'.
        gv_result = |Confirmed: { gv_choice }|.
      ELSE.
        gv_result = 'Confirmation canceled or closed'.
      ENDIF.
    WHEN 'INFO'.
      CALL FUNCTION 'POPUP_TO_INFORM'
        EXPORTING
          titel = 'Information sample'
          txt1  = 'This popup does not change application state.'
          txt2  = 'Close it to return to the dynpro.'.
      gv_result = 'Information popup closed'.
    WHEN 'VALUE'.
      lt_fields = VALUE #( ( tabname = 'SYST' fieldname = 'UNAME'
        fieldtext = 'Example value' value = gv_choice ) ).
      CALL FUNCTION 'POPUP_GET_VALUES'
        EXPORTING
          popup_title     = 'Enter a value'
        TABLES
          fields          = lt_fields
        EXCEPTIONS
          error_in_fields = 1
          OTHERS          = 2.
      IF sy-subrc = 0.
        READ TABLE lt_fields INDEX 1 INTO DATA(ls_field).
        IF sy-subrc = 0.
          gv_choice = ls_field-value.
          gv_result = |Value popup returned { gv_choice }|.
        ENDIF.
      ELSE.
        gv_result = 'Value popup canceled or rejected'.
      ENDIF.
    WHEN 'PROGRESS'.
      DO 5 TIMES.
        cl_progress_indicator=>progress_indicate(
          i_text               = |Progress step { sy-index } of 5|
          i_processed          = sy-index
          i_total              = 5
          i_output_immediately = abap_true ).
      ENDDO.
      gv_result = 'Progress indication completed'.
    WHEN 'RESET'.
      gv_choice = 'ALPHA'.
      gv_dialog_text = 'Editable modal value'.
      gv_result = 'Initial values restored'.
  ENDCASE.
ENDMODULE.

MODULE f4_choice INPUT.
  DATA lt_values TYPE ty_f4_values.
  DATA lt_return TYPE STANDARD TABLE OF ddshretval WITH EMPTY KEY.

  lt_values = VALUE #( ( 'ALPHA' ) ( 'BETA' ) ( 'GAMMA' ) ).
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'VALUE'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'GV_CHOICE'
      value_org       = 'S'
    TABLES
      value_tab       = lt_values
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc = 0.
    READ TABLE lt_return INDEX 1 INTO DATA(ls_return).
    IF sy-subrc = 0.
      gv_choice = ls_return-fieldval.
      gv_result = |F4 returned { gv_choice }|.
    ENDIF.
  ENDIF.
ENDMODULE.

MODULE f1_choice INPUT.
  CALL FUNCTION 'POPUP_TO_INFORM'
    EXPORTING
      titel = 'Choice field help'
      txt1  = 'Use F4 to choose ALPHA, BETA, or GAMMA.'
      txt2  = 'This is custom PROCESS ON HELP-REQUEST logic.'.
  gv_result = 'Custom F1 help was displayed'.
ENDMODULE.

MODULE dialog_exit_0200 INPUT.
  gv_dialog_result = 'Canceled'.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE dialog_command_0200 INPUT.
  DATA lv_dialog_ok_code TYPE sy-ucomm.

  lv_dialog_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  IF lv_dialog_ok_code = 'OK'.
    gv_dialog_result = |Accepted: { gv_dialog_text }|.
    LEAVE TO SCREEN 0.
  ENDIF.
ENDMODULE.
