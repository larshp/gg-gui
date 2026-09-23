CLASS lcl_salv_tree_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_link FOR EVENT link_click OF cl_salv_events_tree
      IMPORTING columnname node_key.
    METHODS on_double FOR EVENT double_click OF cl_salv_events_tree
      IMPORTING columnname node_key.
ENDCLASS.

DATA go_native_salv_tree TYPE REF TO cl_salv_tree.
DATA go_native_salv_events TYPE REF TO cl_salv_events_tree.
DATA go_salv_tree_events TYPE REF TO lcl_salv_tree_events.
DATA gv_tree_factory_error TYPE string.

CLASS lcl_salv_tree_events IMPLEMENTATION.
  METHOD on_link.
    gv_salv_event = 'LINK_CLICK'.
    gv_event_node = node_key.
    gv_event_column = columnname.
    cl_gui_cfw=>set_new_ok_code( new_code = 'SALV_EVT' ).
  ENDMETHOD.

  METHOD on_double.
    gv_salv_event = 'DOUBLE_CLICK'.
    gv_event_node = node_key.
    gv_event_column = columnname.
    cl_gui_cfw=>set_new_ok_code( new_code = 'SALV_EVT' ).
  ENDMETHOD.
ENDCLASS.

FORM create_native_salv_tree.
  CLEAR gv_tree_factory_error.
  TRY.
      cl_salv_tree=>factory(
        EXPORTING r_container = go_host
        IMPORTING r_salv_tree = go_native_salv_tree
        CHANGING  t_table     = gt_rows ).
      go_tree = go_native_salv_tree.
    CATCH cx_root INTO DATA(lx_factory_error).
      CLEAR go_native_salv_tree.
      CLEAR go_tree.
      gv_tree_factory_error = lx_factory_error->get_text( ).
  ENDTRY.
ENDFORM.

FORM register_salv_tree_events.
  IF gv_native_events_registered = abap_true OR go_tree IS NOT BOUND.
    RETURN.
  ENDIF.

  TRY.
      go_native_salv_tree ?= go_tree.
      go_native_salv_events = go_native_salv_tree->get_event( ).
      CREATE OBJECT go_salv_tree_events.
      SET HANDLER go_salv_tree_events->on_link FOR go_native_salv_events.
      SET HANDLER go_salv_tree_events->on_double FOR go_native_salv_events.
      gv_native_events_registered = abap_true.
    CATCH cx_root INTO DATA(lx_event_error).
      CLEAR: go_salv_tree_events, go_native_salv_events, go_native_salv_tree.
      CLEAR gv_native_events_registered.
      gv_detail = |Native SALV tree event registration failed: { lx_event_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM unregister_salv_tree_events.
  IF go_salv_tree_events IS BOUND AND go_native_salv_events IS BOUND.
    SET HANDLER go_salv_tree_events->on_link
      FOR go_native_salv_events ACTIVATION space.
    SET HANDLER go_salv_tree_events->on_double
      FOR go_native_salv_events ACTIVATION space.
  ENDIF.
  CLEAR: go_salv_tree_events, go_native_salv_events, go_native_salv_tree.
  CLEAR: gv_native_events_registered, gv_salv_event, gv_event_node, gv_event_column.
ENDFORM.
