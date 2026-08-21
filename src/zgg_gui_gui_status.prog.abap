REPORT zgg_gui_gui_status.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_input TYPE c LENGTH 40 VALUE 'Right-click this field'.
DATA gv_mode TYPE c LENGTH 20 VALUE 'Normal'.
DATA gv_hide_apply TYPE abap_bool.
DATA gv_disable_context TYPE abap_bool.
DATA gv_result TYPE c LENGTH 70 VALUE 'Use the menu bar, toolbar, keys, or field context menu'.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  DATA lt_excluded TYPE ui_functions.

  IF gv_hide_apply = abap_true.
    APPEND 'APPLY' TO lt_excluded.
    gv_mode = 'Apply excluded'.
  ELSE.
    gv_mode = 'Normal'.
  ENDIF.

  SET PF-STATUS 'MAIN' EXCLUDING lt_excluded.
  SET TITLEBAR 'TITLE_0100' WITH gv_mode.
ENDMODULE.

MODULE exit_0100 INPUT.
  DATA lv_exit_code TYPE sy-ucomm.

  lv_exit_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_exit_code.
    WHEN 'CANCEL'.
      MESSAGE 'Changes canceled' TYPE 'S'.
    WHEN 'EXIT'.
      MESSAGE 'Application exit requested' TYPE 'S'.
  ENDCASE.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.

  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_ok_code.
    WHEN 'APPLY'.
      gv_result = |Applied: { gv_input }|.
    WHEN 'RESET'.
      gv_input = 'Right-click this field'.
      CLEAR: gv_hide_apply, gv_disable_context.
      gv_result = 'Initial status state restored'.
    WHEN 'TOGGLE'.
      IF gv_hide_apply = abap_true.
        CLEAR gv_hide_apply.
      ELSE.
        gv_hide_apply = abap_true.
      ENDIF.
      gv_result = 'The Apply function exclusion was toggled'.
    WHEN 'HELP'.
      CALL FUNCTION 'POPUP_TO_INFORM'
        EXPORTING
          titel = 'GUI status sample'
          txt1  = 'Commands can come from menus, toolbars, or function keys.'
          txt2  = 'Right-click the input field for a dynamic context menu.'.
    WHEN 'CTX_UPPER'.
      TRANSLATE gv_input TO UPPER CASE.
      gv_result = 'Context command converted the value to upper case'.
    WHEN 'CTX_LOWER'.
      TRANSLATE gv_input TO LOWER CASE.
      gv_result = 'Context command converted the value to lower case'.
    WHEN 'CTX_CLEAR'.
      CLEAR gv_input.
      gv_result = 'Context command cleared the value'.
  ENDCASE.
ENDMODULE.

FORM on_ctmenu_input USING io_menu TYPE REF TO cl_ctmenu.
  DATA lo_case_menu TYPE REF TO cl_ctmenu.

  CREATE OBJECT lo_case_menu.
  lo_case_menu->add_function(
    fcode    = 'CTX_UPPER'
    text     = 'Upper case'
    disabled = gv_disable_context ).
  lo_case_menu->add_function(
    fcode    = 'CTX_LOWER'
    text     = 'Lower case'
    disabled = gv_disable_context ).

  io_menu->add_function(
    fcode = 'APPLY'
    text  = 'Apply current value' ).
  io_menu->add_separator( ).
  io_menu->add_submenu(
    menu = lo_case_menu
    text = 'Change case' ).
  io_menu->add_function(
    fcode    = 'CTX_CLEAR'
    text     = 'Clear value'
    disabled = gv_disable_context ).
ENDFORM.
