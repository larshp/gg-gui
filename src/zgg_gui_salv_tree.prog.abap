REPORT zgg_gui_salv_tree.

TYPES ty_price TYPE p LENGTH 8 DECIMALS 2.
CONSTANTS c_price_129 TYPE ty_price VALUE '129.90'.
CONSTANTS c_price_74 TYPE ty_price VALUE '74.50'.
CONSTANTS c_price_389 TYPE ty_price VALUE '389.00'.
CONSTANTS c_price_42 TYPE ty_price VALUE '42.00'.

TYPES:
  BEGIN OF ty_row,
    id       TYPE c LENGTH 8,
    name     TYPE c LENGTH 30,
    category TYPE c LENGTH 20,
    quantity TYPE i,
    price    TYPE ty_price,
    currency TYPE c LENGTH 3,
  END OF ty_row,
  ty_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY,
  ty_keys TYPE STANDARD TABLE OF salv_de_node_key WITH EMPTY KEY,
  ty_text_line TYPE c LENGTH 255,
  ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

DATA gt_rows TYPE ty_rows.
DATA gt_leaf_keys TYPE ty_keys.
DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_tree TYPE REF TO cl_salv_tree.
DATA go_nodes TYPE REF TO cl_salv_nodes.
DATA go_columns TYPE REF TO cl_salv_columns_tree.
DATA go_functions TYPE REF TO cl_salv_functions_tree.
DATA go_selections TYPE REF TO cl_salv_selections_tree.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_root_key TYPE salv_de_node_key.
DATA gv_input_key TYPE salv_de_node_key.
DATA gv_display_key TYPE salv_de_node_key.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_sequence TYPE i VALUE 500.
DATA gv_native_events_registered TYPE abap_bool.
DATA gv_salv_event TYPE c LENGTH 24.
DATA gv_event_node TYPE string.
DATA gv_event_column TYPE c LENGTH 40.

INCLUDE zgg_native_salv_tree.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_controls.
ENDMODULE.

MODULE exit_0100 INPUT.
  PERFORM free_controls.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE dispatch_0100 INPUT.
  DATA lv_return_code TYPE i.

  IF go_tree IS BOUND AND gv_native_events_registered = abap_true.
    cl_gui_cfw=>dispatch( IMPORTING return_code = lv_return_code ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.

  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_ok_code.
    WHEN 'ADD'.
      PERFORM add_runtime_leaf.
    WHEN 'READ'.
      PERFORM read_selection.
    WHEN 'EXPAND'.
      PERFORM expand_all.
    WHEN 'COLLAPSE'.
      PERFORM collapse_all.
    WHEN 'COMPARE'.
      PERFORM compare_tree_apis.
    WHEN 'RESET'.
      PERFORM reset_tree.
    WHEN 'SALV_EVT'.
      IMPORT event = gv_salv_event node_key = gv_event_node
        columnname = gv_event_column FROM MEMORY ID 'ZGG_GUI_SALV_TREE_EVENT'.
      FREE MEMORY ID 'ZGG_GUI_SALV_TREE_EVENT'.
      gv_status = |SALV Tree { gv_salv_event } on node { gv_event_node }|.
      gv_detail = |Event column: { gv_event_column }|.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  DATA lv_error TYPE string.

  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  IF go_tree IS BOUND OR go_fallback IS BOUND.
    RETURN.
  ENDIF.

  TRY.
      PERFORM create_native_salv_tree.
      IF go_tree IS NOT BOUND.
        lv_error = gv_tree_factory_error.
        IF lv_error IS INITIAL.
          lv_error = 'SALV tree factory returned no usable tree'.
        ENDIF.
        PERFORM show_fallback USING lv_error.
        RETURN.
      ENDIF.
      go_nodes = go_tree->get_nodes( ).
      go_columns = go_tree->get_columns( ).
      go_functions = go_tree->get_functions( ).
      go_selections = go_tree->get_selections( ).
      IF go_nodes IS NOT BOUND.
        PERFORM show_fallback USING 'SALV tree factory returned no usable node collection'.
        RETURN.
      ENDIF.
      PERFORM populate_nodes.
      PERFORM configure_columns.
      go_functions->set_all( abap_true ).
      PERFORM register_salv_tree_events.
      go_tree->display( ).
      IF gv_native_events_registered = abap_true.
        gv_status = 'Native SALV tree created with link-click and double-click events'.
      ELSE.
        gv_status = 'Native SALV tree created; native event handler unavailable'.
      ENDIF.
      gv_detail = 'Folder and leaf nodes carry one data row each; items expose per-cell types'.
    CATCH cx_root INTO DATA(lx_error).
      FREE: go_tree, go_nodes, go_columns, go_functions, go_selections.
      lv_error = lx_error->get_text( ).
      PERFORM show_fallback USING lv_error.
  ENDTRY.
ENDFORM.


FORM populate_nodes.
  DATA ls_empty TYPE ty_row.
  DATA lo_node TYPE REF TO cl_salv_node.

  CLEAR: gt_rows, gt_leaf_keys.
  TRY.
      lo_node = go_nodes->add_node(
        related_node   = space
        relationship   = 2
        data_row       = ls_empty
        text           = 'Product catalog'
        folder         = abap_true
        expander       = abap_true
        collapsed_icon = '@3Y@'
        expanded_icon  = '@3W@' ).
      gv_root_key = lo_node->get_key( ).

      lo_node = go_nodes->add_node(
        related_node = gv_root_key
        relationship = 2
        data_row     = ls_empty
        text         = 'Input devices'
        folder       = abap_true
        expander     = abap_true ).
      gv_input_key = lo_node->get_key( ).

      lo_node = go_nodes->add_node(
        related_node = gv_root_key
        relationship = 2
        data_row     = ls_empty
        text         = 'Displays'
        folder       = abap_true
        expander     = abap_true ).
      gv_display_key = lo_node->get_key( ).
    CATCH cx_salv_error INTO DATA(lx_nodes).
      gv_status = |SALV tree folder creation failed: { lx_nodes->get_text( ) }|.
      RETURN.
  ENDTRY.

  PERFORM add_leaf USING gv_input_key 'P100' 'Mechanical Keyboard' 'Input' 12 c_price_129 'EUR'.
  PERFORM add_leaf USING gv_input_key 'P110' 'Ergonomic Mouse' 'Input' 7 c_price_74 'EUR'.
  PERFORM add_leaf USING gv_display_key 'P200' '27 Inch Display' 'Display' 4 c_price_389 'EUR'.
  go_nodes->expand_all( ).
ENDFORM.

FORM add_leaf USING iv_parent TYPE salv_de_node_key iv_id TYPE c iv_name TYPE c
    iv_category TYPE c iv_quantity TYPE i iv_price TYPE ty_price
    iv_currency TYPE c.
  DATA ls_row TYPE ty_row.
  DATA lo_node TYPE REF TO cl_salv_node.
  DATA lo_item TYPE REF TO cl_salv_item.
  DATA lv_key TYPE salv_de_node_key.

  ls_row = VALUE #(
    id = iv_id name = iv_name category = iv_category quantity = iv_quantity
    price = iv_price currency = iv_currency ).
  TRY.
      lo_node = go_nodes->add_node(
        related_node = iv_parent
        relationship = 2
        data_row     = ls_row
        text         = iv_name
        folder       = abap_false ).
      lv_key = lo_node->get_key( ).
      APPEND lv_key TO gt_leaf_keys.
      lo_item = lo_node->get_item( 'NAME' ).
      lo_item->set_type( 4 ).
    CATCH cx_salv_error INTO DATA(lx_leaf).
      gv_status = |SALV tree leaf { iv_id } failed: { lx_leaf->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM configure_columns.
  DATA lo_column TYPE REF TO cl_salv_column.

  go_columns->set_optimize( abap_true ).
  TRY.
      lo_column = go_columns->get_column( 'ID' ).
      lo_column->set_long_text( 'Product identifier' ).
      lo_column->set_output_length( 10 ).
      lo_column = go_columns->get_column( 'PRICE' ).
      lo_column->set_currency_column( 'CURRENCY' ).
    CATCH cx_salv_error INTO DATA(lx_column).
      gv_status = |SALV tree column setup failed: { lx_column->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM add_runtime_leaf.
  DATA lv_id TYPE c LENGTH 8.

  IF go_nodes IS NOT BOUND.
    gv_status = 'SALV tree is unavailable; no runtime leaf can be added'.
    RETURN.
  ENDIF.
  ADD 1 TO gv_sequence.
  lv_id = |P{ gv_sequence }|.
  TRY.
      PERFORM add_leaf USING gv_root_key lv_id 'Runtime SALV tree node'
        'Runtime' gv_sequence c_price_42 'EUR'.
      go_tree->display( ).
      gv_status = |SALV node { lv_id } added under the root and redisplayed|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |SALV node insertion failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM read_selection.
  DATA lt_selected TYPE salv_t_nodes.

  IF go_selections IS NOT BOUND.
    gv_status = 'SALV tree is unavailable; selection cannot be read'.
    RETURN.
  ENDIF.
  TRY.
      lt_selected = go_selections->get_selected_nodes( ).
      gv_status = |SALV tree selection returned { lines( lt_selected ) } nodes|.
      gv_detail = |Leaf keys created by the sample: { lines( gt_leaf_keys ) }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |SALV tree selection read failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM expand_all.
  IF go_nodes IS BOUND.
    TRY.
        go_nodes->expand_all( ).
        gv_status = 'All SALV tree folders expanded'.
      CATCH cx_root INTO DATA(lx_error).
        gv_status = |SALV expand failed: { lx_error->get_text( ) }|.
    ENDTRY.
  ENDIF.
ENDFORM.

FORM collapse_all.
  IF go_nodes IS BOUND.
    TRY.
        go_nodes->collapse_all( ).
        gv_status = 'All SALV tree folders collapsed'.
      CATCH cx_root INTO DATA(lx_error).
        gv_status = |SALV collapse failed: { lx_error->get_text( ) }|.
    ENDTRY.
  ENDIF.
ENDFORM.

FORM compare_tree_apis.
  DATA lo_salv_descr TYPE REF TO cl_abap_typedescr.
  DATA lo_alv_descr TYPE REF TO cl_abap_typedescr.
  DATA lv_salv_available TYPE abap_bool.
  DATA lv_alv_available TYPE abap_bool.

  TRY.
      lo_salv_descr = cl_abap_classdescr=>describe_by_name( 'CL_SALV_TREE' ).
      lv_salv_available = xsdbool( lo_salv_descr IS BOUND ).
    CATCH cx_root.
      lv_salv_available = abap_false.
  ENDTRY.
  TRY.
      lo_alv_descr = cl_abap_classdescr=>describe_by_name( 'CL_GUI_ALV_TREE' ).
      lv_alv_available = xsdbool( lo_alv_descr IS BOUND ).
    CATCH cx_root.
      lv_alv_available = abap_false.
  ENDTRY.
  gv_status = |CL_SALV_TREE available { lv_salv_available }; CL_GUI_ALV_TREE available { lv_alv_available }|.
  gv_detail = 'SALV favors read-only high-level setup; ALV Tree exposes lower-level node/item mutation and toolbar APIs'.
ENDFORM.

FORM reset_tree.
  IF go_nodes IS NOT BOUND.
    gv_status = 'SALV tree is unavailable; the fallback remains visible'.
    RETURN.
  ENDIF.
  TRY.
      go_nodes->delete_all( ).
      gv_sequence = 500.
      PERFORM populate_nodes.
      go_tree->display( ).
      gv_status = 'SALV hierarchy, rows, link item types, expansion, and runtime keys reset'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |SALV tree reset failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM show_fallback USING iv_error TYPE string.
  DATA lt_text TYPE ty_text_lines.

  IF go_fallback IS BOUND.
    RETURN.
  ENDIF.
  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( 'CL_SALV_TREE and its helper classes are unavailable in this runtime.' )
    ( 'The native SAP sample keeps factory, node, column, function, and selection calls behind capability checks.' )
    ( 'Static link-click and double-click handlers require the missing SALV tree event class.' ) ).
  go_fallback->set_text_as_r3table( lt_text ).
  go_fallback->set_readonly_mode( 1 ).
  gv_status = 'SALV tree unavailable; a non-terminating text fallback is displayed'.
  gv_detail = iv_error.
ENDFORM.

FORM free_controls.
  PERFORM unregister_salv_tree_events.
  FREE: go_nodes, go_columns, go_functions, go_selections, go_tree.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
