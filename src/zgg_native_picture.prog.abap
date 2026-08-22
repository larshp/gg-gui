CLASS lcl_picture_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_click FOR EVENT picture_click OF cl_gui_picture
      IMPORTING mouse_pos_x mouse_pos_y.
    METHODS on_double_click FOR EVENT picture_dblclick OF cl_gui_picture
      IMPORTING mouse_pos_x mouse_pos_y.
ENDCLASS.

DATA go_picture_events TYPE REF TO lcl_picture_events.

CLASS lcl_picture_events IMPLEMENTATION.
  METHOD on_click.
    DATA lv_event TYPE c LENGTH 24 VALUE 'PICTURE_CLICK'.

    EXPORT event = lv_event mouse_pos_x = mouse_pos_x mouse_pos_y = mouse_pos_y
      TO MEMORY ID 'ZGG_GUI_PICTURE_EVENT'.
    cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'PIC_EVENT' ).
  ENDMETHOD.

  METHOD on_double_click.
    DATA lv_event TYPE c LENGTH 24 VALUE 'PICTURE_DBLCLICK'.

    EXPORT event = lv_event mouse_pos_x = mouse_pos_x mouse_pos_y = mouse_pos_y
      TO MEMORY ID 'ZGG_GUI_PICTURE_EVENT'.
    cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'PIC_EVENT' ).
  ENDMETHOD.
ENDCLASS.

FORM register_native_picture_events.
  DATA lt_events TYPE cntl_simple_events.

  IF gv_native_events_registered = abap_true OR go_picture IS NOT BOUND.
    RETURN.
  ENDIF.

  TRY.
      CREATE OBJECT go_picture_events.
      lt_events = VALUE #(
        ( eventid = cl_gui_picture=>eventid_picture_click appl_event = abap_true )
        ( eventid = cl_gui_picture=>eventid_picture_dblclick appl_event = abap_true ) ).
      go_picture->set_registered_events(
        EXPORTING events = lt_events
        EXCEPTIONS cntl_error = 1 cntl_system_error = 2
          illegal_event_combination = 3 OTHERS = 4 ).
      IF sy-subrc <> 0.
        FREE go_picture_events.
        RETURN.
      ENDIF.
      SET HANDLER go_picture_events->on_click FOR go_picture.
      SET HANDLER go_picture_events->on_double_click FOR go_picture.
      gv_native_events_registered = abap_true.
    CATCH cx_root INTO DATA(lx_event_error).
      FREE go_picture_events.
      CLEAR gv_native_events_registered.
      gv_status = |Native picture event registration failed: { lx_event_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM unregister_picture_events.
  IF go_picture_events IS BOUND AND go_picture IS BOUND.
    SET HANDLER go_picture_events->on_click FOR go_picture ACTIVATION space.
    SET HANDLER go_picture_events->on_double_click FOR go_picture ACTIVATION space.
  ENDIF.
  FREE go_picture_events.
  CLEAR gv_native_events_registered.
  FREE MEMORY ID 'ZGG_GUI_PICTURE_EVENT'.
ENDFORM.
