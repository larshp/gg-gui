CLASS lcl_delayed_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_delayed FOR EVENT delayed_changed_sel_callback OF cl_gui_alv_grid.
ENDCLASS.

DATA go_delayed_events TYPE REF TO lcl_delayed_events.

CLASS lcl_delayed_events IMPLEMENTATION.
  METHOD on_delayed.
    cl_gui_cfw=>set_new_ok_code( new_code = 'ALV_DELAYED' ).
  ENDMETHOD.
ENDCLASS.

FORM register_native_delayed_event.
  IF gv_native_events_registered = abap_true OR go_grid IS NOT BOUND.
    RETURN.
  ENDIF.

  TRY.
      CREATE OBJECT go_delayed_events.
      SET HANDLER go_delayed_events->on_delayed FOR go_grid.
      go_grid->register_delayed_event( i_event_id = cl_gui_alv_grid=>mc_evt_delayed_change_select ).
      gv_native_events_registered = abap_true.
    CATCH cx_root INTO DATA(lx_event_error).
      CLEAR go_delayed_events.
      CLEAR gv_native_events_registered.
      gv_status = |Native delayed-event registration failed: { lx_event_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM unregister_delayed_event.
  IF go_delayed_events IS BOUND AND go_grid IS BOUND.
    SET HANDLER go_delayed_events->on_delayed FOR go_grid ACTIVATION space.
  ENDIF.
  CLEAR go_delayed_events.
  CLEAR gv_native_events_registered.
ENDFORM.
