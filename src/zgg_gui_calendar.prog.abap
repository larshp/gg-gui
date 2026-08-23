REPORT zgg_gui_calendar.

TYPE-POOLS cnca.

CONSTANTS c_style_vertical TYPE i VALUE 4.
CONSTANTS c_select_day TYPE i VALUE 1.
CONSTANTS c_select_week TYPE i VALUE 2.
CONSTANTS c_select_month TYPE i VALUE 4.
CONSTANTS c_select_interval TYPE i VALUE 8.

DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_calendar TYPE REF TO cl_gui_calendar.
DATA go_control TYPE REF TO cl_gui_control.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_focus TYPE d.
DATA gv_selection_style TYPE i VALUE c_select_day.
DATA gv_style_text TYPE c LENGTH 24.
DATA gv_locale TYPE c LENGTH 60.
DATA gv_status TYPE c LENGTH 104.
DATA gv_native_events_registered TYPE abap_bool.
DATA gv_calendar_event TYPE c LENGTH 24.
DATA gv_event_begin TYPE d.
DATA gv_event_end TYPE d.

INCLUDE zgg_native_calendar.

START-OF-SELECTION.
  gv_focus = sy-datum.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_controls.
  PERFORM describe_state.
ENDMODULE.

MODULE dispatch_0100 INPUT.
  DATA lv_return_code TYPE i.
  IF go_calendar IS BOUND.
    cl_gui_cfw=>dispatch( IMPORTING return_code = lv_return_code ).
  ENDIF.
ENDMODULE.

MODULE exit_0100 INPUT.
  PERFORM free_controls.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.

  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  IF go_calendar IS NOT BOUND AND lv_ok_code <> 'RECREATE'.
    gv_status = 'Calendar class unavailable; use Recreate after installing the native control'.
    RETURN.
  ENDIF.
  CASE lv_ok_code.
    WHEN 'MODE'.
      CASE gv_selection_style.
        WHEN c_select_day.
          gv_selection_style = c_select_interval.
        WHEN c_select_interval.
          gv_selection_style = c_select_day + c_select_week
            + c_select_month + c_select_interval.
        WHEN OTHERS.
          gv_selection_style = c_select_day.
      ENDCASE.
      PERFORM free_calendar.
      PERFORM create_calendar.
    WHEN 'TODAY'.
      gv_focus = sy-datum.
      PERFORM go_to_focus.
    WHEN 'PREVIOUS'.
      gv_focus = gv_focus - 30.
      PERFORM go_to_focus.
    WHEN 'NEXT'.
      gv_focus = gv_focus + 30.
      PERFORM go_to_focus.
    WHEN 'SELECT'.
      PERFORM set_selection.
    WHEN 'READ'.
      PERFORM read_selection.
    WHEN 'MARK'.
      PERFORM set_day_info.
    WHEN 'RESET_INFO'.
      PERFORM reset_day_info.
    WHEN 'RESET_SEL'.
      PERFORM reset_selection.
    WHEN 'RECREATE'.
      PERFORM free_calendar.
      PERFORM create_calendar.
    WHEN 'CAL_EVENT'.
      IMPORT event = gv_calendar_event date_begin = gv_event_begin
        date_end = gv_event_end FROM MEMORY ID 'ZGG_GUI_CALENDAR_EVENT'.
      FREE MEMORY ID 'ZGG_GUI_CALENDAR_EVENT'.
      IF gv_calendar_event = 'INFO_REQUEST'.
        gv_focus = gv_event_begin.
        PERFORM set_day_info.
        gv_status = |INFO_REQUEST view range { gv_event_begin DATE = USER } through { gv_event_end DATE = USER }|.
      ELSE.
        gv_status = |DATE_SELECTED { gv_event_begin DATE = USER } through { gv_event_end DATE = USER }|.
      ENDIF.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  PERFORM create_calendar.
ENDFORM.

FORM create_calendar.
* The control expects CNCA_UTC_DATE character dates, not the ABAP date type.
  DATA lv_focus TYPE cnca_utc_date.

  IF go_calendar IS BOUND.
    RETURN.
  ENDIF.
  lv_focus = gv_focus.
  TRY.
      CREATE OBJECT go_calendar
        EXPORTING
          parent          = go_host
          view_style      = c_style_vertical
          selection_style = gv_selection_style
          focus_date      = lv_focus
          display_months  = 3
          stand_alone     = abap_false
          week_begin_day  = '1'
          week_end        = '67'
          year_begin      = gv_focus(4) - 2
          year_end        = gv_focus(4) + 2.
      go_control ?= go_calendar.
      PERFORM register_calendar_events.
      IF gv_native_events_registered = abap_true.
        gv_status = 'Calendar DATE_SELECTED and INFO_REQUEST events registered'.
      ELSE.
        gv_status = 'Calendar created; native event handler is unavailable'.
      ENDIF.
    CATCH cx_root INTO DATA(lx_error).
      FREE: go_calendar, go_control.
      gv_status = |CL_GUI_CALENDAR unavailable: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.


FORM go_to_focus.
  DATA lv_focus TYPE cnca_utc_date.

  lv_focus = gv_focus.
  TRY.
      go_calendar->go_to_date( lv_focus ).
      gv_status = |Calendar navigated to { gv_focus DATE = USER }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |GO_TO_DATE failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM set_selection.
  DATA lv_end TYPE d.
  DATA lv_begin_utc TYPE cnca_utc_date.
  DATA lv_end_utc TYPE cnca_utc_date.

  lv_end = COND #( WHEN gv_selection_style = c_select_day
    THEN gv_focus ELSE gv_focus + 7 ).
  lv_begin_utc = gv_focus.
  lv_end_utc = lv_end.
  TRY.
      go_calendar->set_selection( date_begin = lv_begin_utc
                                  date_end   = lv_end_utc
                                  no_scroll  = abap_false ).
      gv_status = |Selection set from { gv_focus DATE = USER } to { lv_end DATE = USER }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |SET_SELECTION failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM read_selection.
  DATA lv_begin TYPE d.
  DATA lv_end TYPE d.
  DATA lv_begin_utc TYPE cnca_utc_date.
  DATA lv_end_utc TYPE cnca_utc_date.

  TRY.
      go_calendar->get_selection( IMPORTING date_begin = lv_begin_utc
                                            date_end   = lv_end_utc ).
      lv_begin = lv_begin_utc.
      lv_end = lv_end_utc.
      gv_status = |Selected { lv_begin DATE = USER } through { lv_end DATE = USER }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |GET_SELECTION failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM set_day_info.
  DATA lt_day_info TYPE cnca_itab_day_info.

  lt_day_info = VALUE #(
    ( date = gv_focus color = 1 text = 'Focused sample day' )
    ( date = gv_focus + 1 color = 4 text = 'Follow-up sample day' ) ).
  TRY.
      go_calendar->set_day_info( lt_day_info ).
      gv_status = 'Two dates marked with color and tooltip day information'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |SET_DAY_INFO failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM reset_day_info.
  TRY.
      go_calendar->reset_day_info( ).
      gv_status = 'RESET_DAY_INFO removed the color and tooltip day information'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |RESET_DAY_INFO failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM reset_selection.
  TRY.
      go_calendar->reset_selection( ).
      gv_status = 'RESET_SELECTION cleared the marked days'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |RESET_SELECTION failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM describe_state.
  CASE gv_selection_style.
    WHEN c_select_day.
      gv_style_text = 'Single day'.
    WHEN c_select_interval.
      gv_style_text = 'Date interval'.
    WHEN OTHERS.
      gv_style_text = 'Day/week/month/range'.
  ENDCASE.
  gv_locale = |Focus { gv_focus DATE = USER }; language { sy-langu }; week Monday-Sunday|.
ENDFORM.

FORM free_calendar.
  PERFORM unregister_calendar_events.
  IF go_control IS BOUND. go_control->free( ). FREE go_control. ENDIF.
  FREE go_calendar.
ENDFORM.

FORM free_controls.
  PERFORM free_calendar.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
