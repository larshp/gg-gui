CLASS lcl_calendar_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_date FOR EVENT date_selected OF cl_gui_calendar
      IMPORTING date_begin date_end.
    METHODS on_info FOR EVENT info_request OF cl_gui_calendar
      IMPORTING date_begin date_end.
ENDCLASS.

DATA go_native_calendar TYPE REF TO cl_gui_calendar.
DATA go_calendar_events TYPE REF TO lcl_calendar_events.

CLASS lcl_calendar_events IMPLEMENTATION.
  METHOD on_date.
    DATA lv_event TYPE c LENGTH 24 VALUE 'DATE_SELECTED'.

    EXPORT event = lv_event date_begin = date_begin date_end = date_end
      TO MEMORY ID 'ZGG_GUI_CALENDAR_EVENT'.
    cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'CAL_EVENT' ).
  ENDMETHOD.

  METHOD on_info.
    DATA lv_event TYPE c LENGTH 24 VALUE 'INFO_REQUEST'.

    EXPORT event = lv_event date_begin = date_begin date_end = date_end
      TO MEMORY ID 'ZGG_GUI_CALENDAR_EVENT'.
    cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'CAL_EVENT' ).
  ENDMETHOD.
ENDCLASS.

FORM register_calendar_events.
  DATA lt_events TYPE cntl_simple_events.

  IF gv_native_events_registered = abap_true OR go_calendar IS NOT BOUND.
    RETURN.
  ENDIF.

  TRY.
      go_native_calendar ?= go_calendar.
      CREATE OBJECT go_calendar_events.
      lt_events = VALUE #(
        ( eventid = cl_gui_calendar=>m_id_date_selected appl_event = abap_true )
        ( eventid = cl_gui_calendar=>m_id_info_request appl_event = abap_true ) ).
      go_native_calendar->set_registered_events(
        EXPORTING events = lt_events
        EXCEPTIONS cntl_error = 1 cntl_system_error = 2
          illegal_event_combination = 3 OTHERS = 4 ).
      IF sy-subrc <> 0.
        FREE: go_calendar_events, go_native_calendar.
        RETURN.
      ENDIF.
      SET HANDLER go_calendar_events->on_date FOR go_native_calendar.
      SET HANDLER go_calendar_events->on_info FOR go_native_calendar.
      gv_native_events_registered = abap_true.
    CATCH cx_root INTO DATA(lx_event_error).
      FREE: go_calendar_events, go_native_calendar.
      CLEAR gv_native_events_registered.
      gv_status = |Native calendar event registration failed: { lx_event_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM unregister_calendar_events.
  IF go_calendar_events IS BOUND AND go_native_calendar IS BOUND.
    SET HANDLER go_calendar_events->on_date FOR go_native_calendar ACTIVATION space.
    SET HANDLER go_calendar_events->on_info FOR go_native_calendar ACTIVATION space.
  ENDIF.
  FREE: go_calendar_events, go_native_calendar.
  CLEAR gv_native_events_registered.
  FREE MEMORY ID 'ZGG_GUI_CALENDAR_EVENT'.
ENDFORM.
