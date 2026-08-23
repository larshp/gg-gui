REPORT zgg_gui_modal_selscreen.

TYPE-POOLS icon.

TYPES ty_log_line TYPE c LENGTH 110.
TYPES ty_log TYPE STANDARD TABLE OF ty_log_line WITH EMPTY KEY.

DATA gv_category TYPE c LENGTH 20.
DATA gt_log TYPE ty_log.
DATA gv_exit_command TYPE abap_bool.
DATA gv_calls TYPE i.

* Main selection screen 1000: the calling screen. Titles of the additional
* screens are variables that are filled in INITIALIZATION so the sample keeps
* the repository text-pool convention of report title plus selection texts.
PARAMETERS p_owner TYPE c LENGTH 20 LOWER CASE DEFAULT 'Sample owner'.
SELECTION-SCREEN COMMENT /1(78) g_intro.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN PUSHBUTTON (24) g_modal USER-COMMAND modal.
  SELECTION-SCREEN POSITION 27.
  SELECTION-SCREEN PUSHBUTTON (24) g_full USER-COMMAND full.
  SELECTION-SCREEN POSITION 53.
  SELECTION-SCREEN PUSHBUTTON (24) g_check USER-COMMAND check.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN COMMENT /1(78) g_status.

* Additional selection screen 1100 displayed as a modal dialog window.
SELECTION-SCREEN BEGIN OF SCREEN 1100 AS WINDOW TITLE g_mtitle.
  SELECTION-SCREEN BEGIN OF BLOCK b_modal WITH FRAME TITLE g_btitle.
    PARAMETERS p_city TYPE c LENGTH 20 LOWER CASE DEFAULT 'Walldorf'.
    PARAMETERS p_limit TYPE i DEFAULT 25.
    SELECT-OPTIONS s_cat FOR gv_category NO INTERVALS.
  SELECTION-SCREEN END OF BLOCK b_modal.
SELECTION-SCREEN END OF SCREEN 1100.

* Additional selection screen 1200 used for validation and cancel behavior.
SELECTION-SCREEN BEGIN OF SCREEN 1200 AS WINDOW TITLE g_ctitle.
  PARAMETERS p_code TYPE c LENGTH 4 OBLIGATORY DEFAULT 'GG01'.
  SELECTION-SCREEN COMMENT /1(56) g_hint.
SELECTION-SCREEN END OF SCREEN 1200.

INITIALIZATION.
  g_intro = 'Call additional selection screens as modal windows or fullscreen'.
  g_mtitle = 'Modal selection screen 1100'.
  g_btitle = 'Modal block'.
  g_ctitle = 'Validation and cancel 1200'.
  g_hint = 'Codes must start with GG; Cancel returns SY-SUBRC 4'.
  g_status = 'No additional selection screen has been called yet'.
  WRITE icon_enter_more AS ICON TO g_modal.
  g_modal+4 = ' Modal window'.
  WRITE icon_display AS ICON TO g_full.
  g_full+4 = ' Fullscreen'.
  WRITE icon_okay AS ICON TO g_check.
  g_check+4 = ' Validate/cancel'.
  s_cat[] = VALUE #( ( sign = 'I' option = 'EQ' low = 'Input' ) ).

AT SELECTION-SCREEN OUTPUT.
* Only the fields of the screen currently being sent may be modified.
  CASE sy-dynnr.
    WHEN 1100.
      LOOP AT SCREEN INTO DATA(ls_modal_screen).
        IF ls_modal_screen-name = 'P_CITY'.
          ls_modal_screen-intensified = '1'.
          MODIFY SCREEN FROM ls_modal_screen.
        ENDIF.
      ENDLOOP.
    WHEN 1200.
      LOOP AT SCREEN INTO DATA(ls_check_screen).
        IF ls_check_screen-name = 'P_CODE'.
          ls_check_screen-required = '1'.
          MODIFY SCREEN FROM ls_check_screen.
        ENDIF.
      ENDLOOP.
  ENDCASE.

AT SELECTION-SCREEN ON EXIT-COMMAND.
* Reached for Back, Exit, and Cancel on the called screens as well.
  gv_exit_command = abap_true.
  APPEND |Exit command { sy-ucomm } on screen { sy-dynnr }| TO gt_log.

AT SELECTION-SCREEN ON p_code.
  IF p_code(2) <> 'GG'.
    APPEND |Screen 1200 rejected code { p_code }| TO gt_log.
    SET CURSOR FIELD 'P_CODE'.
    MESSAGE 'Sample codes must start with GG' TYPE 'E'.
  ENDIF.

AT SELECTION-SCREEN ON BLOCK b_modal.
  IF p_limit <= 0.
    APPEND |Screen 1100 rejected limit { p_limit }| TO gt_log.
    SET CURSOR FIELD 'P_LIMIT'.
    MESSAGE 'The limit must be greater than zero' TYPE 'E'.
  ENDIF.

AT SELECTION-SCREEN.
  IF sy-dynnr = 1000.
    CASE sy-ucomm.
      WHEN 'MODAL'.
        PERFORM call_modal.
      WHEN 'FULL'.
        PERFORM call_fullscreen.
      WHEN 'CHECK'.
        PERFORM call_validation.
    ENDCASE.
  ENDIF.

START-OF-SELECTION.
  FORMAT COLOR COL_HEADING INTENSIFIED ON.
  WRITE: / 'ZGG_GUI_MODAL_SELSCREEN - additional selection screens as windows'.
  FORMAT RESET.
  ULINE.
  WRITE: / 'Owner', 20 p_owner,
         / 'Modal city', 20 p_city,
         / 'Modal limit', 20 p_limit,
         / 'Modal category', 20 s_cat-low,
         / 'Validated code', 20 p_code,
         / 'Screen calls', 20 gv_calls.
  SKIP.
  WRITE: / icon_information AS ICON,
    'CALL SELECTION-SCREEN without STARTING AT uses a full screen instead of a window.'.
  SKIP.
  FORMAT COLOR COL_HEADING.
  WRITE: / 'Event log'.
  FORMAT RESET.
  ULINE.
  LOOP AT gt_log INTO DATA(lv_log_line).
    WRITE: / lv_log_line.
  ENDLOOP.

FORM call_modal.
  CLEAR gv_exit_command.
  gv_calls = gv_calls + 1.
  CALL SELECTION-SCREEN 1100 STARTING AT 12 4 ENDING AT 92 16.
  PERFORM log_result USING 'Modal window 1100' sy-subrc.
ENDFORM.

FORM call_fullscreen.
  CLEAR gv_exit_command.
  gv_calls = gv_calls + 1.
  CALL SELECTION-SCREEN 1100.
  PERFORM log_result USING 'Fullscreen 1100' sy-subrc.
ENDFORM.

FORM call_validation.
  CLEAR gv_exit_command.
  gv_calls = gv_calls + 1.
  CALL SELECTION-SCREEN 1200 STARTING AT 20 6 ENDING AT 84 14.
  PERFORM log_result USING 'Modal window 1200' sy-subrc.
ENDFORM.

FORM log_result USING iv_call TYPE string iv_subrc TYPE sy-subrc.
  DATA lv_outcome TYPE c LENGTH 40.

  IF iv_subrc = 0.
    lv_outcome = 'confirmed with Execute'.
  ELSEIF gv_exit_command = abap_true.
    lv_outcome = 'left with an exit command'.
  ELSE.
    lv_outcome = 'canceled'.
  ENDIF.
  g_status = |{ iv_call } { lv_outcome } (SY-SUBRC { iv_subrc })|.
  APPEND |{ iv_call } { lv_outcome }, SY-SUBRC { iv_subrc }| TO gt_log.
ENDFORM.
