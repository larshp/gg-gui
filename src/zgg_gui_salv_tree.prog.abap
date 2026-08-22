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
  ty_keys TYPE STANDARD TABLE OF string WITH EMPTY KEY,
  ty_text_line TYPE c LENGTH 255,
  ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

DATA gt_rows TYPE ty_rows.
DATA gt_leaf_keys TYPE ty_keys.
DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_tree TYPE REF TO object.
DATA go_nodes TYPE REF TO object.
DATA go_columns TYPE REF TO object.
DATA go_functions TYPE REF TO object.
DATA go_selections TYPE REF TO object.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_root_key TYPE string.
DATA gv_input_key TYPE string.
DATA gv_display_key TYPE string.
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
  DATA lv_class TYPE string VALUE 'CL_SALV_TREE'.
  DATA lv_factory TYPE string VALUE 'FACTORY'.
  DATA lv_error TYPE string.

  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  IF go_tree IS BOUND OR go_fallback IS BOUND.
    RETURN.
  ENDIF.

  TRY.
      CALL METHOD (lv_class)=>(lv_factory)
        EXPORTING r_container = go_host container_name = 'CC_MAIN'
        IMPORTING r_salv_tree = go_tree
        CHANGING t_table = gt_rows.
      CALL METHOD go_tree->('GET_NODES') RECEIVING value = go_nodes.
      CALL METHOD go_tree->('GET_COLUMNS') RECEIVING value = go_columns.
      CALL METHOD go_tree->('GET_FUNCTIONS') RECEIVING value = go_functions.
      CALL METHOD go_tree->('GET_SELECTIONS') RECEIVING value = go_selections.
      IF go_tree IS NOT BOUND OR go_nodes IS NOT BOUND.
        PERFORM show_fallback USING 'SALV tree factory returned no usable tree or node collection'.
        RETURN.
      ENDIF.
      PERFORM populate_nodes.
      PERFORM configure_columns.
      CALL METHOD go_functions->('SET_ALL') EXPORTING value = abap_true.
      CALL METHOD go_selections->('SET_SELECTION_MODE') EXPORTING value = 2.
      PERFORM register_salv_tree_events.
      CALL METHOD go_tree->('DISPLAY').
      IF gv_native_events_registered = abap_true.
        gv_status = 'Native SALV tree created with link-click and double-click events'.
      ELSE.
        gv_status = 'Native SALV tree created; native event handler unavailable'.
      ENDIF.
      gv_detail = 'The report uses dynamic calls because the complete SALV tree class family is missing from open-abap'.
    CATCH cx_root INTO DATA(lx_error).
      FREE: go_tree, go_nodes, go_columns, go_functions, go_selections.
      lv_error = lx_error->get_text( ).
      PERFORM show_fallback USING lv_error.
  ENDTRY.
ENDFORM.


FORM populate_nodes.
  DATA ls_empty TYPE ty_row.
  DATA lo_node TYPE REF TO object.

  CLEAR: gt_rows, gt_leaf_keys.
  CALL METHOD go_nodes->('ADD_NODE')
    EXPORTING related_node = space relationship = 2 data_row = ls_empty
      text = 'Product catalog' folder = abap_true expander = abap_true
      collapsed_icon = '@3Y@' expanded_icon = '@3W@'
    RECEIVING node = lo_node.
  CALL METHOD lo_node->('GET_KEY') RECEIVING value = gv_root_key.

  CALL METHOD go_nodes->('ADD_NODE')
    EXPORTING related_node = gv_root_key relationship = 2 data_row = ls_empty
      text = 'Input devices' folder = abap_true expander = abap_true
    RECEIVING node = lo_node.
  CALL METHOD lo_node->('GET_KEY') RECEIVING value = gv_input_key.

  CALL METHOD go_nodes->('ADD_NODE')
    EXPORTING related_node = gv_root_key relationship = 2 data_row = ls_empty
      text = 'Displays' folder = abap_true expander = abap_true
    RECEIVING node = lo_node.
  CALL METHOD lo_node->('GET_KEY') RECEIVING value = gv_display_key.

  PERFORM add_leaf USING gv_input_key 'P100' 'Mechanical Keyboard' 'Input' 12 c_price_129 'EUR'.
  PERFORM add_leaf USING gv_input_key 'P110' 'Ergonomic Mouse' 'Input' 7 c_price_74 'EUR'.
  PERFORM add_leaf USING gv_display_key 'P200' '27 Inch Display' 'Display' 4 c_price_389 'EUR'.
  CALL METHOD go_nodes->('EXPAND_ALL').
ENDFORM.

FORM add_leaf USING iv_parent TYPE string iv_id TYPE c iv_name TYPE c
    iv_category TYPE c iv_quantity TYPE i iv_price TYPE ty_price
    iv_currency TYPE c.
  DATA ls_row TYPE ty_row.
  DATA lo_node TYPE REF TO object.
  DATA lo_item TYPE REF TO object.
  DATA lv_key TYPE string.

  ls_row = VALUE #(
    id = iv_id name = iv_name category = iv_category quantity = iv_quantity
    price = iv_price currency = iv_currency ).
  CALL METHOD go_nodes->('ADD_NODE')
    EXPORTING related_node = iv_parent relationship = 2 data_row = ls_row
      text = iv_name folder = abap_false
    RECEIVING node = lo_node.
  CALL METHOD lo_node->('GET_KEY') RECEIVING value = lv_key.
  APPEND lv_key TO gt_leaf_keys.
  CALL METHOD lo_node->('GET_ITEM') EXPORTING columnname = 'NAME' RECEIVING value = lo_item.
  CALL METHOD lo_item->('SET_TYPE') EXPORTING value = 4.
ENDFORM.

FORM configure_columns.
  DATA lo_column TYPE REF TO object.
  DATA lo_hierarchy TYPE REF TO object.

  CALL METHOD go_columns->('SET_OPTIMIZE') EXPORTING value = abap_true.
  CALL METHOD go_columns->('GET_COLUMN') EXPORTING columnname = 'ID' RECEIVING value = lo_column.
  CALL METHOD lo_column->('SET_LONG_TEXT') EXPORTING value = 'Product identifier'.
  CALL METHOD lo_column->('SET_KEY') EXPORTING value = abap_true.
  CALL METHOD go_columns->('GET_COLUMN') EXPORTING columnname = 'PRICE' RECEIVING value = lo_column.
  CALL METHOD lo_column->('SET_CURRENCY_COLUMN') EXPORTING value = 'CURRENCY'.
  CALL METHOD go_columns->('GET_HIERARCHY_COLUMN') RECEIVING value = lo_hierarchy.
  CALL METHOD lo_hierarchy->('SET_LONG_TEXT') EXPORTING value = 'Product hierarchy'.
  CALL METHOD lo_hierarchy->('SET_TOOLTIP') EXPORTING value = 'SALV tree folder and leaf hierarchy'.
ENDFORM.

FORM add_runtime_leaf.
  IF go_nodes IS NOT BOUND.
    gv_status = 'SALV tree is unavailable; no runtime leaf can be added'.
    RETURN.
  ENDIF.
  ADD 1 TO gv_sequence.
  DATA lv_id TYPE c LENGTH 8.

  lv_id = |P{ gv_sequence }|.
  TRY.
      PERFORM add_leaf USING gv_root_key lv_id 'Runtime SALV tree node'
        'Runtime' gv_sequence c_price_42 'EUR'.
      CALL METHOD go_tree->('REFRESH').
      gv_status = |SALV node { lv_id } added under the root and refreshed|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |SALV node insertion failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM read_selection.
  DATA lt_selected TYPE ty_keys.

  IF go_selections IS NOT BOUND.
    gv_status = 'SALV tree is unavailable; selection cannot be read'.
    RETURN.
  ENDIF.
  TRY.
      CALL METHOD go_selections->('GET_SELECTED_NODES') RECEIVING value = lt_selected.
      gv_status = |SALV multiple-selection returned { lines( lt_selected ) } node keys|.
      gv_detail = |Leaf keys created by the sample: { lines( gt_leaf_keys ) }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |SALV tree selection read failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM expand_all.
  IF go_nodes IS BOUND.
    TRY.
        CALL METHOD go_nodes->('EXPAND_ALL').
        gv_status = 'All SALV tree folders expanded'.
      CATCH cx_root INTO DATA(lx_error).
        gv_status = |SALV expand failed: { lx_error->get_text( ) }|.
    ENDTRY.
  ENDIF.
ENDFORM.

FORM collapse_all.
  IF go_nodes IS BOUND.
    TRY.
        CALL METHOD go_nodes->('COLLAPSE_ALL').
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
      CALL METHOD go_nodes->('DELETE_ALL').
      gv_sequence = 500.
      PERFORM populate_nodes.
      CALL METHOD go_tree->('REFRESH').
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
  go_fallback->set_text_as_r3table( table = lt_text ).
  go_fallback->set_readonly_mode( readonly_mode = 1 ).
  gv_status = 'SALV tree unavailable; a non-terminating text fallback is displayed'.
  gv_detail = iv_error.
ENDFORM.

FORM free_controls.
  PERFORM unregister_salv_tree_events.
  FREE: go_nodes, go_columns, go_functions, go_selections, go_tree.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
