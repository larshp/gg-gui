REPORT zgg_gui_tree_models.

TYPES:
  BEGIN OF ty_node,
    node_key  TYPE tv_nodekey,
    relatkey  TYPE tv_nodekey,
    relatship TYPE i,
    hidden    TYPE abap_bool,
    disabled  TYPE abap_bool,
    isfolder  TYPE abap_bool,
    n_image   TYPE tv_image,
    exp_image TYPE tv_image,
    style     TYPE i,
    no_branch TYPE abap_bool,
    expander  TYPE abap_bool,
    text      TYPE c LENGTH 80,
  END OF ty_node,
  ty_nodes TYPE STANDARD TABLE OF ty_node WITH EMPTY KEY.
TYPES:
  BEGIN OF ty_item,
    node_key   TYPE tv_nodekey,
    item_name  TYPE tv_itmname,
    class      TYPE i,
    font       TYPE i,
    disabled   TYPE abap_bool,
    editable   TYPE abap_bool,
    hidden     TYPE abap_bool,
    alignment  TYPE i,
    t_image    TYPE tv_image,
    chosen     TYPE abap_bool,
    togg_right TYPE abap_bool,
    style      TYPE i,
    length     TYPE i,
    length_pix TYPE abap_bool,
    ignoreimag TYPE abap_bool,
    usebgcolor TYPE abap_bool,
    txtisqinfo TYPE abap_bool,
    text       TYPE c LENGTH 80,
  END OF ty_item,
  ty_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.
TYPES:
  BEGIN OF ty_header,
    heading TYPE c LENGTH 40,
    tooltip TYPE c LENGTH 80,
    width   TYPE i,
  END OF ty_header.
TYPES ty_class_names TYPE STANDARD TABLE OF string WITH EMPTY KEY.
TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_model TYPE REF TO object.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_active_model TYPE c LENGTH 24.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_model IS NOT BOUND AND go_fallback IS NOT BOUND.
    PERFORM show_default.
  ENDIF.
ENDMODULE.

MODULE exit_0100 INPUT.
  PERFORM release_model.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.
  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_ok_code.
    WHEN 'SIMPLE'.
      PERFORM show_simple_model.
    WHEN 'LIST'.
      PERFORM show_list_model.
    WHEN 'COLUMN'.
      PERFORM show_column_model.
    WHEN 'COMPARE'.
      PERFORM show_comparison.
    WHEN 'RESET'.
      CASE gv_active_model.
        WHEN 'CL_SIMPLE_TREE_MODEL'. PERFORM show_simple_model.
        WHEN 'CL_LIST_TREE_MODEL'. PERFORM show_list_model.
        WHEN 'CL_COLUMN_TREE_MODEL'. PERFORM show_column_model.
        WHEN OTHERS. PERFORM show_default.
      ENDCASE.
  ENDCASE.
ENDMODULE.

FORM class_exists USING iv_class TYPE string CHANGING cv_exists TYPE abap_bool.
  DATA lo_descr TYPE REF TO cl_abap_typedescr.

  cv_exists = abap_false.
  TRY.
      lo_descr = cl_abap_classdescr=>describe_by_name( iv_class ).
      cv_exists = xsdbool( lo_descr IS BOUND ).
    CATCH cx_root.
      cv_exists = abap_false.
  ENDTRY.
ENDFORM.

FORM prepare_host.
  PERFORM release_model.
  CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
ENDFORM.

FORM show_default.
  DATA lv_simple TYPE abap_bool.

  PERFORM class_exists USING 'CL_SIMPLE_TREE_MODEL' CHANGING lv_simple.
  IF lv_simple = abap_true.
    PERFORM show_simple_model.
  ELSE.
    PERFORM show_comparison.
  ENDIF.
ENDFORM.

FORM show_simple_model.
  DATA lv_class TYPE string VALUE 'CL_SIMPLE_TREE_MODEL'.
  DATA lv_available TYPE abap_bool.
  DATA lv_reason TYPE string.
  DATA lt_nodes TYPE ty_nodes.

  PERFORM prepare_host.
  PERFORM class_exists USING lv_class CHANGING lv_available.
  IF lv_available = abap_false.
    PERFORM show_missing USING lv_class.
    RETURN.
  ENDIF.
  lt_nodes = VALUE #(
    ( node_key = 'ROOT' isfolder = abap_true text = 'Simple Tree Model' n_image = '@04@' exp_image = '@05@' )
    ( node_key = 'INPUT' relatkey = 'ROOT' relatship = 6 isfolder = abap_true text = 'Input devices' )
    ( node_key = 'P100' relatkey = 'INPUT' relatship = 6 text = 'Mechanical Keyboard' )
    ( node_key = 'P110' relatkey = 'INPUT' relatship = 6 text = 'Ergonomic Mouse' ) ).
  TRY.
      CREATE OBJECT go_model TYPE (lv_class)
        EXPORTING node_selection_mode = 1 hide_selection = abap_false.
      CALL METHOD go_model->('ADD_NODES') EXPORTING nodes_table = lt_nodes.
      CALL METHOD go_model->('CREATE_TREE_CONTROL') EXPORTING parent = go_host.
      CALL METHOD go_model->('EXPAND_NODE') EXPORTING node_key = 'ROOT'.
      gv_active_model = lv_class.
      gv_status = 'Simple Tree Model created with folder/leaf nodes and one text value per node'.
      gv_detail = 'Backend CL_SIMPLE_TREE_MODEL owns data; CREATE_TREE_CONTROL supplies the frontend view'.
    CATCH cx_root INTO DATA(lx_error).
      lv_reason = lx_error->get_text( ).
      PERFORM show_failure USING lv_class lv_reason.
  ENDTRY.
ENDFORM.

FORM show_list_model.
  DATA lv_class TYPE string VALUE 'CL_LIST_TREE_MODEL'.
  DATA lv_available TYPE abap_bool.
  DATA lv_reason TYPE string.
  DATA ls_header TYPE ty_header.
  DATA lt_nodes TYPE ty_nodes.
  DATA lt_items TYPE ty_items.

  PERFORM prepare_host.
  PERFORM class_exists USING lv_class CHANGING lv_available.
  IF lv_available = abap_false.
    PERFORM show_missing USING lv_class.
    RETURN.
  ENDIF.
  ls_header = VALUE #( heading = 'List Tree Model' tooltip = 'Multiple items arranged as a list' width = 32 ).
  lt_nodes = VALUE #(
    ( node_key = 'ROOT' isfolder = abap_true n_image = '@04@' exp_image = '@05@' )
    ( node_key = 'P100' relatkey = 'ROOT' relatship = 6 )
    ( node_key = 'P200' relatkey = 'ROOT' relatship = 6 ) ).
  lt_items = VALUE #(
    ( node_key = 'ROOT' item_name = 'NODE' class = 1 text = 'List Tree Model' )
    ( node_key = 'P100' item_name = 'NODE' class = 1 text = 'P100' )
    ( node_key = 'P100' item_name = 'NAME' class = 1 text = 'Mechanical Keyboard' )
    ( node_key = 'P200' item_name = 'NODE' class = 1 text = 'P200' )
    ( node_key = 'P200' item_name = 'NAME' class = 1 text = '27 Inch Display' ) ).
  TRY.
      CREATE OBJECT go_model TYPE (lv_class)
        EXPORTING node_selection_mode = 1 hide_selection = abap_false
          item_selection = abap_true hierarchy_header = ls_header.
      CALL METHOD go_model->('ADD_NODES') EXPORTING node_table = lt_nodes.
      CALL METHOD go_model->('ADD_ITEMS') EXPORTING item_table = lt_items.
      CALL METHOD go_model->('CREATE_TREE_CONTROL') EXPORTING parent = go_host.
      CALL METHOD go_model->('EXPAND_NODE') EXPORTING node_key = 'ROOT'.
      gv_active_model = lv_class.
      gv_status = 'List Tree Model created with multiple ordered items per node'.
      gv_detail = 'List layout adds item classes and item selection while retaining a backend model lifecycle'.
    CATCH cx_root INTO DATA(lx_error).
      lv_reason = lx_error->get_text( ).
      PERFORM show_failure USING lv_class lv_reason.
  ENDTRY.
ENDFORM.

FORM show_column_model.
  DATA lv_class TYPE string VALUE 'CL_COLUMN_TREE_MODEL'.
  DATA lv_available TYPE abap_bool.
  DATA lv_reason TYPE string.
  DATA ls_header TYPE ty_header.
  DATA lt_nodes TYPE ty_nodes.
  DATA lt_items TYPE ty_items.

  PERFORM prepare_host.
  PERFORM class_exists USING lv_class CHANGING lv_available.
  IF lv_available = abap_false.
    PERFORM show_missing USING lv_class.
    RETURN.
  ENDIF.
  ls_header = VALUE #( heading = 'Product hierarchy' tooltip = 'Column Tree Model hierarchy' width = 28 ).
  lt_nodes = VALUE #(
    ( node_key = 'ROOT' isfolder = abap_true n_image = '@04@' exp_image = '@05@' )
    ( node_key = 'P100' relatkey = 'ROOT' relatship = 6 )
    ( node_key = 'P200' relatkey = 'ROOT' relatship = 6 ) ).
  lt_items = VALUE #(
    ( node_key = 'ROOT' item_name = 'NODE' class = 1 text = 'Column Tree Model' )
    ( node_key = 'ROOT' item_name = 'NAME' class = 1 text = 'Backend model' )
    ( node_key = 'ROOT' item_name = 'STATE' class = 1 text = 'Ready' )
    ( node_key = 'P100' item_name = 'NODE' class = 1 text = 'P100' )
    ( node_key = 'P100' item_name = 'NAME' class = 1 text = 'Mechanical Keyboard' )
    ( node_key = 'P100' item_name = 'STATE' class = 3 text = 'Selected' chosen = abap_true )
    ( node_key = 'P200' item_name = 'NODE' class = 1 text = 'P200' )
    ( node_key = 'P200' item_name = 'NAME' class = 1 text = '27 Inch Display' )
    ( node_key = 'P200' item_name = 'STATE' class = 1 text = 'Ready' ) ).
  TRY.
      CREATE OBJECT go_model TYPE (lv_class)
        EXPORTING node_selection_mode = 1 hide_selection = abap_false
          item_selection = abap_true hierarchy_column_name = 'NODE'
          hierarchy_header = ls_header.
      CALL METHOD go_model->('ADD_COLUMN')
        EXPORTING name = 'NAME' width = 28 header_text = 'Product'.
      CALL METHOD go_model->('ADD_COLUMN')
        EXPORTING name = 'STATE' width = 14 header_text = 'State'.
      CALL METHOD go_model->('ADD_NODES') EXPORTING node_table = lt_nodes.
      CALL METHOD go_model->('ADD_ITEMS') EXPORTING item_table = lt_items.
      CALL METHOD go_model->('CREATE_TREE_CONTROL') EXPORTING parent = go_host.
      CALL METHOD go_model->('EXPAND_NODE') EXPORTING node_key = 'ROOT'.
      gv_active_model = lv_class.
      gv_status = 'Column Tree Model created with hierarchy, data columns, text, and checkbox items'.
      gv_detail = 'Column model offers the richest item/column layout while the backend model owns node state'.
    CATCH cx_root INTO DATA(lx_error).
      lv_reason = lx_error->get_text( ).
      PERFORM show_failure USING lv_class lv_reason.
  ENDTRY.
ENDFORM.

FORM show_comparison.
  DATA lt_names TYPE ty_class_names.
  DATA lt_text TYPE ty_text_lines.
  DATA lv_available TYPE abap_bool.

  PERFORM prepare_host.
  lt_names = VALUE #(
    ( `CL_GUI_SIMPLE_TREE` ) ( `CL_SIMPLE_TREE_MODEL` )
    ( `CL_GUI_LIST_TREE` ) ( `CL_LIST_TREE_MODEL` )
    ( `CL_GUI_COLUMN_TREE` ) ( `CL_COLUMN_TREE_MODEL` ) ).
  lt_text = VALUE #(
    ( 'Low-level controls keep application-owned tables and transfer changes directly to the frontend.' )
    ( 'Tree Model classes keep a backend object model, then create and synchronize their frontend control.' )
    ( 'Simple: one text per node. List: multiple list items. Column: named columns and rich item classes.' ) ).
  LOOP AT lt_names INTO DATA(lv_name).
    PERFORM class_exists USING lv_name CHANGING lv_available.
    APPEND CONV ty_text_line( |{ lv_name }: available { lv_available }| ) TO lt_text.
  ENDLOOP.
  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  go_fallback->set_text_as_r3table( lt_text ).
  go_fallback->set_readonly_mode( 1 ).
  CLEAR gv_active_model.
  gv_status = 'Tree control versus Tree Model capability comparison displayed'.
  gv_detail = 'Use Simple, List, or Column to create an installed model; missing classes are reported without terminating'.
ENDFORM.

FORM show_missing USING iv_class TYPE string.
  DATA lv_reason TYPE string.

  lv_reason = |{ iv_class } is not present in this ABAP runtime|.
  PERFORM show_failure USING iv_class lv_reason.
ENDFORM.

FORM show_failure USING iv_class TYPE string iv_reason TYPE string.
  DATA lt_text TYPE ty_text_lines.

  FREE go_model.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  lt_text = VALUE #(
    ( |{ iv_class } is unavailable or could not create its frontend tree.| )
    ( |Reason: { iv_reason }| )
    ( 'The native backend-model, node/item, CREATE_TREE_CONTROL, expand, reset, and cleanup calls remain in this report.' ) ).
  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  go_fallback->set_text_as_r3table( lt_text ).
  go_fallback->set_readonly_mode( 1 ).
  CLEAR gv_active_model.
  gv_status = |{ iv_class } unavailable; diagnostic fallback shown|.
  gv_detail = iv_reason.
ENDFORM.

FORM release_model.
  IF go_model IS BOUND.
    TRY.
        CALL METHOD go_model->('DESTROY_TREE_CONTROL').
      CATCH cx_root.
    ENDTRY.
    FREE go_model.
  ENDIF.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
