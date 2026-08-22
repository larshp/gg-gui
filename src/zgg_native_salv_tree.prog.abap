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

CLASS lcl_salv_tree_events IMPLEMENTATION.
  METHOD on_link.
    DATA lv_event TYPE c LENGTH 24 VALUE 'LINK_CLICK'.

    EXPORT event = lv_event node_key = node_key columnname = columnname
      TO MEMORY ID 'ZGG_GUI_SALV_TREE_EVENT'.
    cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'SALV_EVT' ).
  ENDMETHOD.

  METHOD on_double.
    DATA lv_event TYPE c LENGTH 24 VALUE 'DOUBLE_CLICK'.

    EXPORT event = lv_event node_key = node_key columnname = columnname
      TO MEMORY ID 'ZGG_GUI_SALV_TREE_EVENT'.
    cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'SALV_EVT' ).
  ENDMETHOD.
ENDCLASS.

FORM create_native_salv_tree.
  cl_salv_tree=>factory(
    EXPORTING r_container  = go_host
              container_name = 'CC_MAIN'
    IMPORTING r_salv_tree  = go_native_salv_tree
    CHANGING  t_table      = gt_rows ).
  go_tree = go_native_salv_tree.
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
      FREE: go_salv_tree_events, go_native_salv_events, go_native_salv_tree.
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
  FREE: go_salv_tree_events, go_native_salv_events, go_native_salv_tree.
  CLEAR gv_native_events_registered.
  FREE MEMORY ID 'ZGG_GUI_SALV_TREE_EVENT'.
ENDFORM.
