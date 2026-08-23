REPORT zgg_gui_popups LINE-SIZE 132 LINE-COUNT 40.

TYPE-POOLS icon.

TYPES:
  BEGIN OF ty_demo,
    code    TYPE c LENGTH 10,
    caption TYPE c LENGTH 34,
    api     TYPE c LENGTH 28,
    purpose TYPE c LENGTH 58,
  END OF ty_demo,
  ty_demos TYPE STANDARD TABLE OF ty_demo WITH EMPTY KEY.

TYPES ty_table_row TYPE c LENGTH 62.
TYPES ty_table_rows TYPE STANDARD TABLE OF ty_table_row WITH EMPTY KEY.
TYPES ty_log_line TYPE c LENGTH 120.
TYPES ty_log TYPE STANDARD TABLE OF ty_log_line WITH EMPTY KEY.

DATA gv_code TYPE c LENGTH 10.
DATA gt_log TYPE ty_log.
DATA gv_name TYPE c LENGTH 12 VALUE 'Sample user'.
DATA gv_date TYPE d.
DATA gv_time TYPE t.
DATA gv_month TYPE c LENGTH 6.

START-OF-SELECTION.
  gv_date = sy-datum.
  gv_time = sy-uzeit.
  gv_month = sy-datum(6).
  PERFORM write_menu.

AT LINE-SELECTION.
  IF gv_code IS INITIAL.
    MESSAGE 'Select one of the popup rows' TYPE 'S'.
    RETURN.
  ENDIF.

  CASE gv_code.
    WHEN 'CONFIRM'.
      PERFORM popup_confirm.
    WHEN 'CONFIRM3'.
      PERFORM popup_confirm_cancel.
    WHEN 'INFORM'.
      PERFORM popup_inform.
    WHEN 'VALUES'.
      PERFORM popup_values.
    WHEN 'REQUIRED'.
      PERFORM popup_values_required.
    WHEN 'TABLE'.
      PERFORM popup_table.
    WHEN 'MONTH'.
      PERFORM popup_month.
    WHEN 'MESSAGE'.
      PERFORM message_dialogs.
    WHEN 'RESET'.
      CLEAR gt_log.
      gv_name = 'Sample user'.
      gv_date = sy-datum.
      gv_time = sy-uzeit.
      gv_month = sy-datum(6).
      PERFORM log USING 'Sample values and the result log were reset'.
  ENDCASE.

* Rebuild the basic list so the result log stays on one list level.
  sy-lsind = 0.
  PERFORM write_menu.

FORM write_menu.
  DATA lt_demos TYPE ty_demos.

  lt_demos = VALUE #(
    ( code = 'CONFIRM' caption = 'Two-button confirmation'
      api = 'POPUP_TO_CONFIRM'
      purpose = 'Question with two labeled buttons and a default button' )
    ( code = 'CONFIRM3' caption = 'Confirmation with Cancel'
      api = 'POPUP_TO_CONFIRM'
      purpose = 'Distinguish button 1, button 2, and the Cancel answer A' )
    ( code = 'INFORM' caption = 'Information popup'
      api = 'POPUP_TO_INFORM'
      purpose = 'Non-blocking information that changes no application state' )
    ( code = 'VALUES' caption = 'Value entry popup'
      api = 'POPUP_GET_VALUES'
      purpose = 'Character, date, and time fields typed through DDIC' )
    ( code = 'REQUIRED' caption = 'Value entry with required field'
      api = 'POPUP_GET_VALUES'
      purpose = 'Obligatory field plus returncode A when the user cancels' )
    ( code = 'TABLE' caption = 'Selection from a table'
      api = 'POPUP_WITH_TABLE_DISPLAY'
      purpose = 'Pick one row of an internal table and read its index' )
    ( code = 'MONTH' caption = 'Month selection'
      api = 'POPUP_TO_SELECT_MONTH'
      purpose = 'Calendar-aware month picker returning YYYYMM' )
    ( code = 'MESSAGE' caption = 'Message-based dialogs'
      api = 'MESSAGE TYPE I/W/S'
      purpose = 'Modal message dialog, warning, and status-bar message' )
    ( code = 'RESET' caption = 'Reset sample values'
      api = 'Local'
      purpose = 'Restore the initial values and clear the result log' ) ).

  FORMAT COLOR COL_HEADING INTENSIFIED ON.
  WRITE: / 'ZGG_GUI_POPUPS - standard SAP GUI popup dialogs'.
  FORMAT RESET.
  ULINE.
  WRITE: / icon_information AS ICON,
    'Select a row to open the popup. Obsolete variants are listed at the end.'.
  SKIP.

  FORMAT COLOR COL_HEADING.
  WRITE: / 'Action', 38 'Function module', 68 'Purpose'.
  FORMAT RESET.
  ULINE.
  LOOP AT lt_demos INTO DATA(ls_demo).
    gv_code = ls_demo-code.
    WRITE: / ls_demo-caption HOTSPOT COLOR COL_KEY,
             38 ls_demo-api,
             68 ls_demo-purpose.
    HIDE gv_code.
  ENDLOOP.
  CLEAR gv_code.

  SKIP.
  FORMAT COLOR COL_HEADING.
  WRITE: / 'Current sample values'.
  FORMAT RESET.
  ULINE.
  WRITE: / 'Name', 20 gv_name,
         / 'Date', 20 gv_date,
         / 'Time', 20 gv_time,
         / 'Month', 20 gv_month.

  SKIP.
  FORMAT COLOR COL_HEADING.
  WRITE: / 'Result log'.
  FORMAT RESET.
  ULINE.
  IF gt_log IS INITIAL.
    WRITE: / 'No popup has been called yet'.
  ENDIF.
  LOOP AT gt_log INTO DATA(lv_line).
    WRITE: / lv_line.
  ENDLOOP.

  SKIP.
  FORMAT COLOR COL_HEADING.
  WRITE: / 'Deliberately not covered'.
  FORMAT RESET.
  ULINE.
  WRITE: / 'POPUP_TO_DECIDE, POPUP_TO_DECIDE_LIST, POPUP_TO_GET_VALUE, and the',
         / 'POPUP_TO_CONFIRM_* variants are obsolete. SAP replaces all of them with',
         / 'POPUP_TO_CONFIRM shown above; new code should not call them.',
         / 'Value help through F4IF_INT_TABLE_VALUE_REQUEST is shown in ZGG_GUI_DIALOGS_HELP.'.
ENDFORM.

FORM popup_confirm.
  DATA lv_message TYPE string.
  DATA lv_answer TYPE c LENGTH 1.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Two-button confirmation'
      text_question         = 'Apply the current sample values?'
      text_button_1         = 'Apply'
      icon_button_1         = 'ICON_OKAY'
      text_button_2         = 'Discard'
      icon_button_2         = 'ICON_CANCEL'
      default_button        = '1'
      display_cancel_button = abap_false
      start_column          = 25
      start_row             = 6
    IMPORTING
      answer                = lv_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  IF sy-subrc <> 0.
    PERFORM log USING 'POPUP_TO_CONFIRM could not be displayed'.
    RETURN.
  ENDIF.
  lv_message = |POPUP_TO_CONFIRM answer { lv_answer } (1 = Apply, 2 = Discard)|.
  PERFORM log USING lv_message.
ENDFORM.

FORM popup_confirm_cancel.
  DATA lv_message TYPE string.
  DATA lv_answer TYPE c LENGTH 1.
  DATA lv_meaning TYPE c LENGTH 40.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Confirmation with Cancel'
      text_question         = 'Keep the changed values, discard them, or cancel?'
      text_button_1         = 'Keep'
      text_button_2         = 'Discard'
      default_button        = '2'
      display_cancel_button = abap_true
      start_column          = 25
      start_row             = 6
    IMPORTING
      answer                = lv_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  IF sy-subrc <> 0.
    PERFORM log USING 'POPUP_TO_CONFIRM could not be displayed'.
    RETURN.
  ENDIF.
  CASE lv_answer.
    WHEN '1'.
      lv_meaning = 'button 1 was chosen'.
    WHEN '2'.
      lv_meaning = 'button 2 was chosen'.
    WHEN 'A'.
      lv_meaning = 'the popup was canceled or closed'.
    WHEN OTHERS.
      lv_meaning = 'no answer was returned'.
  ENDCASE.
  lv_message = |POPUP_TO_CONFIRM answer { lv_answer }: { lv_meaning }|.
  PERFORM log USING lv_message.
ENDFORM.

FORM popup_inform.
  CALL FUNCTION 'POPUP_TO_INFORM'
    EXPORTING
      titel = 'Information popup'
      txt1  = 'Information popups report a result and change nothing.'
      txt2  = 'Close the popup to return to the list.'.
  PERFORM log USING 'POPUP_TO_INFORM was closed'.
ENDFORM.

FORM popup_values.
  DATA lv_message TYPE string.
  DATA lt_fields TYPE STANDARD TABLE OF sval WITH EMPTY KEY.
  DATA lv_returncode TYPE c LENGTH 1.

  lt_fields = VALUE #(
    ( tabname = 'SYST' fieldname = 'UNAME' fieldtext = 'Name' value = gv_name )
    ( tabname = 'SYST' fieldname = 'DATUM' fieldtext = 'Date' value = gv_date )
    ( tabname = 'SYST' fieldname = 'UZEIT' fieldtext = 'Time' value = gv_time ) ).

  CALL FUNCTION 'POPUP_GET_VALUES'
    EXPORTING
      popup_title     = 'Typed value entry'
      start_column    = 25
      start_row       = 6
    IMPORTING
      returncode      = lv_returncode
    TABLES
      fields          = lt_fields
    EXCEPTIONS
      error_in_fields = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
    PERFORM log USING 'POPUP_GET_VALUES reported an error in the field list'.
    RETURN.
  ENDIF.
  IF lv_returncode = 'A'.
    PERFORM log USING 'POPUP_GET_VALUES was canceled; no value was taken over'.
    RETURN.
  ENDIF.

  READ TABLE lt_fields INDEX 1 INTO DATA(ls_name).
  IF sy-subrc = 0.
    gv_name = ls_name-value.
  ENDIF.
  READ TABLE lt_fields INDEX 2 INTO DATA(ls_date).
  IF sy-subrc = 0.
    gv_date = ls_date-value.
  ENDIF.
  READ TABLE lt_fields INDEX 3 INTO DATA(ls_time).
  IF sy-subrc = 0.
    gv_time = ls_time-value.
  ENDIF.
  lv_message = |POPUP_GET_VALUES returned { gv_name }, { gv_date }, { gv_time }|.
  PERFORM log USING lv_message.
ENDFORM.

FORM popup_values_required.
  DATA lv_message TYPE string.
  DATA lt_fields TYPE STANDARD TABLE OF sval WITH EMPTY KEY.
  DATA lv_returncode TYPE c LENGTH 1.

  lt_fields = VALUE #(
    ( tabname = 'SYST' fieldname = 'UNAME' fieldtext = 'Name'
      value = gv_name field_obl = abap_true )
    ( tabname = 'SYST' fieldname = 'DATUM' fieldtext = 'Date'
      value = gv_date novaluehlp = abap_true ) ).

  CALL FUNCTION 'POPUP_GET_VALUES'
    EXPORTING
      no_value_check  = abap_false
      popup_title     = 'Required field and suppressed value help'
      start_column    = 25
      start_row       = 6
    IMPORTING
      returncode      = lv_returncode
    TABLES
      fields          = lt_fields
    EXCEPTIONS
      error_in_fields = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
    PERFORM log USING 'POPUP_GET_VALUES rejected the field definition'.
    RETURN.
  ENDIF.
  IF lv_returncode = 'A'.
    PERFORM log USING 'Required-field popup canceled; the obligatory field kept its old value'.
    RETURN.
  ENDIF.
  READ TABLE lt_fields INDEX 1 INTO DATA(ls_name).
  IF sy-subrc = 0.
    gv_name = ls_name-value.
  ENDIF.
  lv_message = |Required-field popup confirmed with name { gv_name }|.
  PERFORM log USING lv_message.
ENDFORM.

FORM popup_table.
  DATA lv_message TYPE string.
  DATA lt_demo TYPE zcl_gg_gui_demo_data=>ty_products.
  DATA lt_values TYPE ty_table_rows.
  DATA lv_index TYPE sy-tabix.

  lt_demo = zcl_gg_gui_demo_data=>products( ).
  LOOP AT lt_demo INTO DATA(ls_product).
    APPEND |{ ls_product-id } { ls_product-name } { ls_product-category }| TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'POPUP_WITH_TABLE_DISPLAY'
    EXPORTING
      endpos_col   = 90
      endpos_row   = 16
      startpos_col = 20
      startpos_row = 5
      titletext    = 'Choose a product'
    IMPORTING
      choise       = lv_index
    TABLES
      valuetab     = lt_values
    EXCEPTIONS
      break_off    = 1
      OTHERS       = 2.
  IF sy-subrc <> 0.
    PERFORM log USING 'POPUP_WITH_TABLE_DISPLAY was left without a selection'.
    RETURN.
  ENDIF.
  READ TABLE lt_values INDEX lv_index INTO DATA(lv_row).
  IF sy-subrc = 0.
    lv_message = |POPUP_WITH_TABLE_DISPLAY returned row { lv_index }: { lv_row }|.
    PERFORM log USING lv_message.
  ENDIF.
ENDFORM.

FORM popup_month.
  DATA lv_message TYPE string.
  DATA lv_selected TYPE c LENGTH 6.
  DATA lv_return_code TYPE c LENGTH 1.

  CALL FUNCTION 'POPUP_TO_SELECT_MONTH'
    EXPORTING
      actual_month               = gv_month
      language                   = sy-langu
      start_column               = 25
      start_row                  = 6
    IMPORTING
      return_code                = lv_return_code
      selected_month             = lv_selected
    EXCEPTIONS
      factory_calendar_not_found = 1
      holiday_calendar_not_found = 2
      month_not_found            = 3
      OTHERS                     = 4.
  IF sy-subrc <> 0.
    PERFORM log USING 'POPUP_TO_SELECT_MONTH is unavailable on this system'.
    RETURN.
  ENDIF.
  IF lv_return_code IS NOT INITIAL OR lv_selected IS INITIAL.
    PERFORM log USING 'Month selection canceled; the previous month is kept'.
    RETURN.
  ENDIF.
  gv_month = lv_selected.
  lv_message = |POPUP_TO_SELECT_MONTH returned { gv_month }|.
  PERFORM log USING lv_message.
ENDFORM.

FORM message_dialogs.
* Message type I opens a modal dialog, W and S write to the status bar of the
* following screen. None of them terminates list processing.
  MESSAGE 'Message type I is displayed as a modal dialog box' TYPE 'I'.
  MESSAGE 'Message type W is displayed in the status bar' TYPE 'W'.
  PERFORM log USING 'Message dialogs shown: type I as a dialog, type W in the status bar'.
  MESSAGE 'Message type S appears on the next list screen' TYPE 'S'.
ENDFORM.

FORM log USING iv_text TYPE string.
  APPEND iv_text TO gt_log.
ENDFORM.
