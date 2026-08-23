REPORT zgg_gui_navigation.

TYPES ty_log_line TYPE c LENGTH 110.
TYPES ty_log TYPE STANDARD TABLE OF ty_log_line WITH EMPTY KEY.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 90.
DATA gv_stack TYPE c LENGTH 60.
DATA gv_memory TYPE c LENGTH 60.
DATA gv_report TYPE c LENGTH 40 VALUE 'ZGG_GUI_CATALOG'.
DATA gv_depth TYPE i.
DATA gv_replaced TYPE abap_bool.
DATA gt_log TYPE ty_log.

START-OF-SELECTION.
  PERFORM log USING 'START-OF-SELECTION reached; CALL SCREEN 0100 opens the first screen sequence'.
  CALL SCREEN 0100.

MODULE status_0100 OUTPUT.
  PERFORM refresh_state.
ENDMODULE.

MODULE status_0200 OUTPUT.
  PERFORM refresh_state.
ENDMODULE.

MODULE status_0300 OUTPUT.
  PERFORM refresh_state.
ENDMODULE.

* Screen 0400 is never displayed: its PBO suppresses the dialog and switches
* directly to list processing, which is the classic way of reaching a list from
* a screen sequence without showing an intermediate dynpro.
MODULE suppress_0400 OUTPUT.
  SUPPRESS DIALOG.
  LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0.
  PERFORM write_log_list USING 'Screen 0400 was suppressed with SUPPRESS DIALOG'.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  PERFORM log USING 'Exit command on 0100; LEAVE TO SCREEN 0 ends the sequence and the report'.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE exit_0200 INPUT.
  CLEAR gv_ok_code.
  PERFORM log USING 'Exit command on 0200; LEAVE TO SCREEN 0 returns to the calling screen'.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE exit_0300 INPUT.
  CLEAR gv_ok_code.
  IF gv_replaced = abap_true.
    CLEAR gv_replaced.
    PERFORM log USING 'Exit command on the replaced screen 0300; SET SCREEN 0100 restores the main screen'.
    SET SCREEN 0100.
    LEAVE SCREEN.
  ENDIF.
  PERFORM log USING 'Exit command on the called screen 0300; LEAVE TO SCREEN 0 leaves the call level'.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.
  DATA lv_memory TYPE c LENGTH 40.
  DATA lv_answer TYPE c LENGTH 1.

  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_ok_code.
    WHEN 'CALL200'.
      PERFORM log USING 'CALL SCREEN 0200 stacks a new screen sequence on top of 0100'.
      gv_depth = gv_depth + 1.
      CALL SCREEN 0200.
      gv_depth = gv_depth - 1.
      PERFORM log USING 'Control returned to the statement after CALL SCREEN 0200'.
      gv_status = 'Returned from the called screen sequence 0200'.
    WHEN 'REPLACE'.
      gv_replaced = abap_true.
      PERFORM log USING 'SET SCREEN 0300 plus LEAVE SCREEN replaces 0100 without stacking'.
      SET SCREEN 0300.
      LEAVE SCREEN.
    WHEN 'LIST'.
      PERFORM log USING 'LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0100 switches to the list'.
      LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0100.
      PERFORM write_log_list USING 'List processing started from the PAI of screen 0100'.
    WHEN 'SUPPRESS'.
      PERFORM log USING 'CALL SCREEN 0400 runs a screen whose PBO suppresses the dialog'.
      CALL SCREEN 0400.
      gv_status = 'Returned from the suppressed screen 0400'.
    WHEN 'PARAM'.
      SET PARAMETER ID 'RID' FIELD gv_report.
      GET PARAMETER ID 'RID' FIELD lv_memory.
      gv_memory = |SPA/GPA parameter RID = { lv_memory }|.
      PERFORM log USING 'SET PARAMETER ID and GET PARAMETER ID exchange values through SAP memory'.
      gv_status = 'SAP memory parameter RID was set and read back'.
    WHEN 'SUBMIT'.
      PERFORM log USING 'SUBMIT ... AND RETURN starts another report and resumes here afterwards'.
      SUBMIT zgg_gui_sel_layout AND RETURN.
      gv_status = 'Returned from the submitted report ZGG_GUI_SEL_LAYOUT'.
    WHEN 'TCODE'.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar      = 'Call transaction'
          text_question = 'Call transaction SE38 and return afterwards?'
          text_button_1 = 'Call'
          text_button_2 = 'Cancel'
        IMPORTING
          answer        = lv_answer.
      IF lv_answer <> '1'.
        gv_status = 'Transaction call canceled by the user'.
        RETURN.
      ENDIF.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SE38'.
      IF sy-subrc <> 0.
        gv_status = 'Missing S_TCODE authorization for SE38; nothing was called'.
        PERFORM log USING 'AUTHORITY-CHECK for S_TCODE failed; the transaction was not called'.
        RETURN.
      ENDIF.
      SET PARAMETER ID 'RID' FIELD gv_report.
      PERFORM log USING 'CALL TRANSACTION with AND SKIP FIRST SCREEN consumes the SPA/GPA parameter'.
      CALL TRANSACTION 'SE38' AND SKIP FIRST SCREEN.
      gv_status = 'Returned from the called transaction'.
    WHEN 'RESET'.
      CLEAR: gt_log, gv_memory, gv_replaced.
      gv_status = 'Navigation log and SAP memory display reset'.
      PERFORM log USING 'Sample state reset'.
    WHEN 'LEAVE'.
      PERFORM log USING 'LEAVE PROGRAM ends the report immediately'.
      LEAVE PROGRAM.
  ENDCASE.
ENDMODULE.

MODULE user_command_0200 INPUT.
  DATA lv_cmd_0200 TYPE sy-ucomm.

  lv_cmd_0200 = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_cmd_0200.
    WHEN 'CALL300'.
      PERFORM log USING 'CALL SCREEN 0300 stacks a second call level'.
      gv_depth = gv_depth + 1.
      CALL SCREEN 0300.
      gv_depth = gv_depth - 1.
      PERFORM log USING 'Control returned to the statement after CALL SCREEN 0300'.
    WHEN 'SET0'.
      PERFORM log USING 'SET SCREEN 0 plus LEAVE SCREEN behaves like LEAVE TO SCREEN 0'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'RETURN'.
      PERFORM log USING 'LEAVE TO SCREEN 0 ends the called sequence 0200'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.

MODULE user_command_0300 INPUT.
  DATA lv_cmd_0300 TYPE sy-ucomm.

  lv_cmd_0300 = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_cmd_0300.
    WHEN 'MAIN'.
      CLEAR gv_replaced.
      PERFORM log USING 'SET SCREEN 0100 plus LEAVE SCREEN returns to the main screen by replacement'.
      SET SCREEN 0100.
      LEAVE SCREEN.
    WHEN 'RETURN'.
      CLEAR gv_replaced.
      PERFORM log USING 'LEAVE TO SCREEN 0 leaves the current screen level'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.

MODULE exit_0400 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

FORM refresh_state.
  gv_stack = |Screen { sy-dynnr }, call level { gv_depth }, replaced { gv_replaced }|.
  IF gv_status IS INITIAL.
    gv_status = 'Choose a navigation statement; the log records every transition'.
  ENDIF.
ENDFORM.

FORM log USING iv_text TYPE string.
  APPEND |{ sy-dynnr }: { iv_text }| TO gt_log.
ENDFORM.

FORM write_log_list USING iv_headline TYPE string.
  FORMAT COLOR COL_HEADING INTENSIFIED ON.
  WRITE: / 'ZGG_GUI_NAVIGATION - screen sequence and list processing'.
  FORMAT RESET.
  ULINE.
  WRITE: / iv_headline.
  SKIP.
  WRITE: / 'Use Back to return to the screen named in the RETURN TO SCREEN addition.'.
  SKIP.
  FORMAT COLOR COL_HEADING.
  WRITE: / 'Navigation log'.
  FORMAT RESET.
  ULINE.
  LOOP AT gt_log INTO DATA(lv_line).
    WRITE: / lv_line.
  ENDLOOP.
ENDFORM.
