REPORT zgg_gui_tabstrip.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_subscreen TYPE sy-dynnr VALUE '0110'.
DATA gv_tab1_title TYPE c LENGTH 20 VALUE 'Identity'.
DATA gv_tab2_title TYPE c LENGTH 20 VALUE 'Settings'.
DATA gv_tab3_title TYPE c LENGTH 20 VALUE 'Advanced'.
DATA gv_show_advanced TYPE abap_bool VALUE abap_true.
DATA gv_name TYPE c LENGTH 30 VALUE 'Ada Lovelace'.
DATA gv_role TYPE c LENGTH 20 VALUE 'Developer'.
DATA gv_notify TYPE abap_bool VALUE abap_true.
DATA gv_start_date TYPE d VALUE sy-datum.
DATA gv_note TYPE c LENGTH 50 VALUE 'Values remain while switching pages'.
DATA gv_status TYPE c LENGTH 60.

CONTROLS ts_main TYPE TABSTRIP.

START-OF-SELECTION.
  ts_main-activetab = 'TAB1'.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  gv_tab1_title = |Identity: { gv_name }|.
  IF gv_notify = abap_true.
    gv_tab2_title = 'Settings: notify'.
  ELSE.
    gv_tab2_title = 'Settings: quiet'.
  ENDIF.

  LOOP AT SCREEN.
    IF screen-name = 'GV_TAB3_TITLE'.
      IF gv_show_advanced = abap_true.
        screen-invisible = 0.
      ELSE.
        screen-invisible = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
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
    WHEN 'TAB1'.
      ts_main-activetab = 'TAB1'.
      gv_subscreen = '0110'.
    WHEN 'TAB2'.
      ts_main-activetab = 'TAB2'.
      gv_subscreen = '0120'.
    WHEN 'TAB3'.
      IF gv_show_advanced = abap_true.
        ts_main-activetab = 'TAB3'.
        gv_subscreen = '0130'.
      ENDIF.
    WHEN 'APPLY'.
      gv_status = |Active page { ts_main-activetab } was applied|.
    WHEN 'RESET'.
      gv_name = 'Ada Lovelace'.
      gv_role = 'Developer'.
      gv_notify = abap_true.
      gv_start_date = sy-datum.
      gv_note = 'Values remain while switching pages'.
      gv_show_advanced = abap_true.
      ts_main-activetab = 'TAB1'.
      gv_subscreen = '0110'.
      gv_status = 'Initial tab values restored'.
  ENDCASE.

  IF gv_show_advanced = abap_false AND ts_main-activetab = 'TAB3'.
    ts_main-activetab = 'TAB1'.
    gv_subscreen = '0110'.
  ENDIF.
ENDMODULE.

MODULE validate_identity INPUT.
  IF gv_name IS INITIAL.
    MESSAGE 'Name is required on the Identity page' TYPE 'E'.
  ENDIF.
ENDMODULE.

MODULE validate_settings INPUT.
  IF gv_start_date IS INITIAL.
    MESSAGE 'Start date is required on the Settings page' TYPE 'E'.
  ENDIF.
ENDMODULE.
