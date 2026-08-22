CLASS lcl_context_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_request FOR EVENT node_context_menu_request OF cl_gui_alv_tree
      IMPORTING node_key menu.
ENDCLASS.

DATA go_context_events TYPE REF TO lcl_context_events.

CLASS lcl_context_events IMPLEMENTATION.
  METHOD on_request.
    menu->add_separator( ).
    menu->add_function( fcode = 'ZDETAIL' text = 'Show node details' ).
    menu->add_function( fcode = 'ZRESET' text = 'Reset sample' ).
    EXPORT node_key = node_key TO MEMORY ID 'ZGG_GUI_ALV_TREE_CTX'.
    cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'TREE_CTX' ).
  ENDMETHOD.
ENDCLASS.

FORM register_native_context_event.
  DATA lt_events TYPE cntl_simple_events.

  IF gv_native_events_registered = abap_true OR go_tree IS NOT BOUND.
    RETURN.
  ENDIF.

  TRY.
      go_tree->get_registered_events(
        IMPORTING events = lt_events
        EXCEPTIONS cntl_error = 1 OTHERS = 2 ).
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      DELETE lt_events WHERE eventid = cl_gui_column_tree=>eventid_node_context_menu_req.
      APPEND VALUE #(
        eventid = cl_gui_column_tree=>eventid_node_context_menu_req
        appl_event = abap_true ) TO lt_events.
      go_tree->set_registered_events(
        EXPORTING events = lt_events
        EXCEPTIONS cntl_error = 1 cntl_system_error = 2
          illegal_event_combination = 3 OTHERS = 4 ).
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      CREATE OBJECT go_context_events.
      SET HANDLER go_context_events->on_request FOR go_tree.
      gv_native_events_registered = abap_true.
    CATCH cx_root INTO DATA(lx_event_error).
      FREE go_context_events.
      CLEAR gv_native_events_registered.
      gv_detail = |Native tree context-event registration failed: { lx_event_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM unregister_context_event.
  IF go_context_events IS BOUND AND go_tree IS BOUND.
    SET HANDLER go_context_events->on_request FOR go_tree ACTIVATION space.
  ENDIF.
  FREE go_context_events.
  CLEAR gv_native_events_registered.
  FREE MEMORY ID 'ZGG_GUI_ALV_TREE_CTX'.
ENDFORM.
