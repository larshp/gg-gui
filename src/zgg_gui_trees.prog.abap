REPORT zgg_gui_trees.

TYPES:
  BEGIN OF ty_node,
    node_key   TYPE tv_nodekey,
    relatkey   TYPE tv_nodekey,
    relatship  TYPE i,
    hidden     TYPE abap_bool,
    disabled   TYPE abap_bool,
    isfolder   TYPE abap_bool,
    n_image    TYPE tv_image,
    exp_image  TYPE tv_image,
    style      TYPE i,
    no_branch  TYPE abap_bool,
    expander   TYPE abap_bool,
    dragdropid TYPE i,
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
TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.
TYPES ty_class_names TYPE STANDARD TABLE OF string WITH EMPTY KEY.

CLASS lcl_events DEFINITION.
  PUBLIC SECTION.
    METHODS on_selection FOR EVENT selection_changed OF cl_gui_column_tree
      IMPORTING node_key.
    METHODS on_node_double FOR EVENT node_double_click OF cl_gui_column_tree
      IMPORTING node_key.
    METHODS on_item_double FOR EVENT item_double_click OF cl_gui_column_tree
      IMPORTING node_key item_name.
    METHODS on_expand FOR EVENT expand_no_children OF cl_gui_column_tree
      IMPORTING node_key.
    METHODS on_checkbox FOR EVENT checkbox_change OF cl_gui_column_tree
      IMPORTING node_key item_name checked.
    METHODS on_button FOR EVENT button_click OF cl_gui_column_tree
      IMPORTING node_key item_name.
    METHODS on_header FOR EVENT header_click OF cl_gui_column_tree
      IMPORTING header_name.
    METHODS on_node_menu FOR EVENT node_context_menu_request OF cl_gui_column_tree
      IMPORTING node_key menu.
    METHODS on_item_menu FOR EVENT item_context_menu_request OF cl_gui_column_tree
      IMPORTING node_key item_name menu.
    METHODS on_key FOR EVENT item_keypress OF cl_gui_column_tree
      IMPORTING node_key item_name key.
ENDCLASS.

DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_tree TYPE REF TO cl_gui_column_tree.
DATA go_events TYPE REF TO lcl_events.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gt_nodes TYPE ty_nodes.
DATA gt_items TYPE ty_items.
DATA gt_added_keys TYPE treev_nks.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_event TYPE c LENGTH 108.
DATA gv_sequence TYPE i.
DATA gv_hidden TYPE abap_bool.
DATA gv_moved TYPE abap_bool.
DATA gv_lazy_loaded TYPE abap_bool.
DATA gv_header_alt TYPE abap_bool.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_selection.
    gv_event = |Selection changed: node { node_key }|.
  ENDMETHOD.

  METHOD on_node_double.
    gv_event = |Node double-click: { node_key }|.
  ENDMETHOD.

  METHOD on_item_double.
    gv_event = |Item double-click: { node_key }/{ item_name }|.
  ENDMETHOD.

  METHOD on_expand.
    gv_event = |Lazy expansion requested for node { node_key }|.
    IF node_key = 'LAZY'.
      PERFORM add_lazy_children.
    ENDIF.
  ENDMETHOD.

  METHOD on_checkbox.
    gv_event = |Checkbox { node_key }/{ item_name } changed to { checked }|.
  ENDMETHOD.

  METHOD on_button.
    gv_event = |Item button { node_key }/{ item_name } clicked|.
  ENDMETHOD.

  METHOD on_header.
    gv_event = |Column header { header_name } clicked|.
  ENDMETHOD.

  METHOD on_node_menu.
    menu->add_function( fcode = 'NODE_INFO' text = |Describe { node_key }| ).
    menu->add_function( fcode = 'NODE_EXPAND' text = 'Expand subtree' ).
    gv_event = |Node context menu requested for { node_key }|.
  ENDMETHOD.

  METHOD on_item_menu.
    menu->add_function( fcode = 'ITEM_INFO' text = |Describe { item_name }| ).
    gv_event = |Item context menu requested for { node_key }/{ item_name }|.
  ENDMETHOD.

  METHOD on_key.
    gv_event = |Item key event { key } on { node_key }/{ item_name }|.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_controls.
ENDMODULE.

MODULE dispatch_0100 INPUT.
  DATA lv_return_code TYPE i.

  IF go_tree IS BOUND.
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
  IF go_tree IS NOT BOUND AND lv_ok_code <> 'AUDIT'.
    gv_status = 'Native column tree unavailable; class audit remains usable'.
    RETURN.
  ENDIF.
  CASE lv_ok_code.
    WHEN 'ADD'.
      PERFORM add_node.
    WHEN 'CHANGE'.
      PERFORM change_item.
    WHEN 'MOVE'.
      PERFORM move_node.
    WHEN 'DELETE'.
      PERFORM delete_node.
    WHEN 'EXPAND'.
      go_tree->expand_node( node_key = 'ROOT' level_count = 3 expand_subtree = abap_true ).
      gv_status = 'Root expanded through the column-tree API'.
    WHEN 'COLLAPSE'.
      go_tree->collapse_subtree( 'ROOT' ).
      gv_status = 'Root subtree collapsed'.
    WHEN 'SELECT'.
      PERFORM select_nodes.
    WHEN 'READ'.
      PERFORM read_state.
    WHEN 'COLUMN'.
      PERFORM toggle_column.
    WHEN 'HEADER'.
      PERFORM change_header.
    WHEN 'AUDIT'.
      PERFORM audit_classes.
    WHEN 'RESET'.
      PERFORM reset_tree.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  DATA ls_header TYPE treev_hhdr.

  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  IF go_tree IS BOUND OR go_fallback IS BOUND.
    RETURN.
  ENDIF.

  ls_header-heading = 'Tree subject'.
  ls_header-tooltip = 'Hierarchy column; double-click and use context menus'.
  ls_header-width = 30.
  TRY.
      CREATE OBJECT go_tree
        EXPORTING parent = go_host
          node_selection_mode = cl_gui_column_tree=>node_sel_mode_multiple
          item_selection = abap_true hierarchy_column_name = 'NODE'
          hierarchy_header = ls_header.
      CREATE OBJECT go_events.
      SET HANDLER go_events->on_selection FOR go_tree.
      SET HANDLER go_events->on_node_double FOR go_tree.
      SET HANDLER go_events->on_item_double FOR go_tree.
      SET HANDLER go_events->on_expand FOR go_tree.
      SET HANDLER go_events->on_checkbox FOR go_tree.
      SET HANDLER go_events->on_button FOR go_tree.
      SET HANDLER go_events->on_header FOR go_tree.
      SET HANDLER go_events->on_node_menu FOR go_tree.
      SET HANDLER go_events->on_item_menu FOR go_tree.
      SET HANDLER go_events->on_key FOR go_tree.
      PERFORM add_columns.
      PERFORM register_events.
      PERFORM build_initial_data.
      PERFORM transfer_all_data.
      go_tree->expand_root_nodes( level_count = 2 ).
      gv_status = 'Column tree created with text, checkbox, button, link, icon, and editable items'.
      gv_event = 'Select, double-click, expand Lazy children, or request a context menu'.
    CATCH cx_root INTO DATA(lx_error).
      FREE: go_tree, go_events.
      PERFORM show_fallback USING lx_error.
  ENDTRY.
ENDFORM.

FORM add_columns.
  go_tree->add_column(
    name = 'NAME' width = 28 header_text = 'Example'
    header_tooltip = 'Control or behavior demonstrated' ).
  go_tree->add_column(
    name = 'KIND' width = 18 header_text = 'Item class'
    header_tooltip = 'Text, checkbox, link, or button' ).
  go_tree->add_column(
    name = 'STATE' width = 18 alignment = cl_gui_column_tree=>align_center
    header_text = 'State' header_tooltip = 'Editable and chosen state' ).
ENDFORM.

FORM register_events.
  DATA lt_events TYPE cntl_simple_events.

  lt_events = VALUE #(
    ( eventid = cl_gui_column_tree=>eventid_selection_changed appl_event = abap_true )
    ( eventid = cl_gui_column_tree=>eventid_node_double_click appl_event = abap_true )
    ( eventid = cl_gui_column_tree=>eventid_item_double_click appl_event = abap_true )
    ( eventid = cl_gui_column_tree=>eventid_expand_no_children appl_event = abap_true )
    ( eventid = cl_gui_column_tree=>eventid_checkbox_change appl_event = abap_true )
    ( eventid = cl_gui_column_tree=>eventid_button_click appl_event = abap_true )
    ( eventid = cl_gui_column_tree=>eventid_header_click appl_event = abap_true )
    ( eventid = cl_gui_column_tree=>eventid_node_context_menu_req appl_event = abap_true )
    ( eventid = cl_gui_column_tree=>eventid_item_context_menu_req appl_event = abap_true )
    ( eventid = cl_gui_column_tree=>eventid_item_keypress appl_event = abap_true ) ).
  go_tree->set_registered_events( lt_events ).
  go_tree->set_ctx_menu_select_event_appl( abap_true ).
ENDFORM.

FORM build_initial_data.
  CLEAR: gt_nodes, gt_items, gt_added_keys.
  gt_nodes = VALUE #(
    ( node_key = 'ROOT' isfolder = abap_true n_image = '@04@' exp_image = '@05@' )
    ( node_key = 'CORE' relatkey = 'ROOT'
      relatship = cl_gui_column_tree=>relat_last_child isfolder = abap_true
      n_image = '@04@' exp_image = '@05@' )
    ( node_key = 'CONTAINERS' relatkey = 'CORE'
      relatship = cl_gui_column_tree=>relat_last_child n_image = '@3Y@' )
    ( node_key = 'LAZY' relatkey = 'ROOT'
      relatship = cl_gui_column_tree=>relat_last_child isfolder = abap_true
      expander = abap_true n_image = '@04@' exp_image = '@05@' )
    ( node_key = 'EVENTS' relatkey = 'ROOT'
      relatship = cl_gui_column_tree=>relat_last_child n_image = '@3P@' ) ).

  gt_items = VALUE #(
    ( node_key = 'ROOT' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text
      text = 'Tree controls' style = cl_gui_column_tree=>style_emphasized )
    ( node_key = 'ROOT' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text
      text = 'Low-level column tree' t_image = '@3P@' )
    ( node_key = 'ROOT' item_name = 'KIND' class = cl_gui_column_tree=>item_class_text text = 'folder' )
    ( node_key = 'ROOT' item_name = 'STATE' class = cl_gui_column_tree=>item_class_text text = 'expanded' )
    ( node_key = 'CORE' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'Core API' )
    ( node_key = 'CORE' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = 'Inherited tree methods' )
    ( node_key = 'CORE' item_name = 'KIND' class = cl_gui_column_tree=>item_class_text text = 'text' )
    ( node_key = 'CORE' item_name = 'STATE' class = cl_gui_column_tree=>item_class_checkbox
      text = 'chosen' chosen = abap_true editable = abap_true )
    ( node_key = 'CONTAINERS' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'Containers' )
    ( node_key = 'CONTAINERS' item_name = 'NAME' class = cl_gui_column_tree=>item_class_button
      text = 'Open item button' t_image = '@15@' )
    ( node_key = 'CONTAINERS' item_name = 'KIND' class = cl_gui_column_tree=>item_class_text text = 'button' )
    ( node_key = 'CONTAINERS' item_name = 'STATE' class = cl_gui_column_tree=>item_class_text text = 'ready' )
    ( node_key = 'LAZY' item_name = 'NODE' class = cl_gui_column_tree=>item_class_link text = 'Lazy children' )
    ( node_key = 'LAZY' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = 'Expand to load nodes' )
    ( node_key = 'LAZY' item_name = 'KIND' class = cl_gui_column_tree=>item_class_text text = 'link/folder' )
    ( node_key = 'LAZY' item_name = 'STATE' class = cl_gui_column_tree=>item_class_text text = 'not loaded' )
    ( node_key = 'EVENTS' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'Events' )
    ( node_key = 'EVENTS' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = 'Selection and context' )
    ( node_key = 'EVENTS' item_name = 'KIND' class = cl_gui_column_tree=>item_class_text text = 'text' )
    ( node_key = 'EVENTS' item_name = 'STATE' class = cl_gui_column_tree=>item_class_text text = 'interactive' ) ).
ENDFORM.

FORM transfer_all_data.
  go_tree->add_nodes_and_items(
    node_table = gt_nodes item_table = gt_items
    item_table_structure_name = 'MTREEITM' ).
ENDFORM.

FORM add_node.
  DATA lt_nodes TYPE ty_nodes.
  DATA lt_items TYPE ty_items.
  DATA lv_key TYPE tv_nodekey.

  ADD 1 TO gv_sequence.
  lv_key = |EXTRA{ gv_sequence WIDTH = 3 PAD = '0' }|.
  lt_nodes = VALUE #( ( node_key = lv_key relatkey = 'ROOT'
    relatship = cl_gui_column_tree=>relat_last_child n_image = '@3Y@' ) ).
  lt_items = VALUE #(
    ( node_key = lv_key item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = lv_key )
    ( node_key = lv_key item_name = 'NAME' class = cl_gui_column_tree=>item_class_button text = 'Added at runtime' )
    ( node_key = lv_key item_name = 'KIND' class = cl_gui_column_tree=>item_class_text text = 'button' )
    ( node_key = lv_key item_name = 'STATE' class = cl_gui_column_tree=>item_class_checkbox
      text = 'new' editable = abap_true ) ).
  go_tree->add_nodes_and_items(
    node_table = lt_nodes item_table = lt_items
    item_table_structure_name = 'MTREEITM' ).
  APPEND LINES OF lt_nodes TO gt_nodes.
  APPEND LINES OF lt_items TO gt_items.
  APPEND lv_key TO gt_added_keys.
  go_tree->ensure_visible( lv_key ).
  gv_status = |Node { lv_key } added under ROOT and scrolled into view|.
ENDFORM.

FORM change_item.
  DATA lt_items TYPE ty_items.

  READ TABLE gt_items ASSIGNING FIELD-SYMBOL(<item>)
    WITH KEY node_key = 'CORE' item_name = 'NAME'.
  IF sy-subrc = 0.
    <item>-text = COND #( WHEN <item>-text = 'Inherited tree methods'
      THEN 'Updated without rebuilding' ELSE 'Inherited tree methods' ).
    APPEND <item> TO lt_items.
    go_tree->update_nodes_and_items(
      item_table = lt_items item_table_structure_name = 'MTREEITM' ).
  ENDIF.
  go_tree->item_set_chosen( node_key = 'CORE' item_name = 'STATE' chosen = abap_true ).
  go_tree->item_set_editable( node_key = 'CORE' item_name = 'STATE' editable = abap_true ).
  go_tree->item_set_t_image( node_key = 'CORE' item_name = 'NAME' t_image = '@0V@' ).
  gv_status = 'CORE item text, icon, chosen state, and editability updated in place'.
ENDFORM.

FORM move_node.
  DATA lv_parent TYPE tv_nodekey.

  gv_moved = xsdbool( gv_moved = abap_false ).
  lv_parent = COND #( WHEN gv_moved = abap_true THEN 'LAZY' ELSE 'ROOT' ).
  TRY.
      CALL METHOD go_tree->('MOVE_NODE')
        EXPORTING node_key = 'EVENTS' relative_node_key = lv_parent
          relationship = cl_gui_column_tree=>relat_last_child.
      gv_status = |EVENTS moved under { lv_parent }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |MOVE_NODE unavailable: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM delete_node.
  DATA lt_keys TYPE treev_nks.
  DATA lv_key TYPE tv_nodekey.

  IF gt_added_keys IS INITIAL.
    gv_status = 'Add a runtime node before using Delete'.
    RETURN.
  ENDIF.
  READ TABLE gt_added_keys INDEX lines( gt_added_keys ) INTO lv_key.
  APPEND lv_key TO lt_keys.
  go_tree->delete_nodes( lt_keys ).
  DELETE gt_nodes WHERE node_key = lv_key.
  DELETE gt_items WHERE node_key = lv_key.
  DELETE gt_added_keys INDEX lines( gt_added_keys ).
  gv_status = |Node { lv_key } and its items deleted|.
ENDFORM.

FORM select_nodes.
  DATA lt_keys TYPE treev_nks.

  lt_keys = VALUE #( ( 'CORE' ) ( 'EVENTS' ) ).
  go_tree->select_nodes( lt_keys ).
  go_tree->ensure_visible( 'EVENTS' ).
  go_tree->set_top_node( 'ROOT' ).
  gv_status = 'CORE and EVENTS selected; EVENTS made visible and ROOT retained as top node'.
ENDFORM.

FORM read_state.
  DATA lt_selected TYPE treev_nks.
  DATA lt_expanded TYPE treev_nks.

  go_tree->get_selected_nodes( CHANGING node_key_table = lt_selected ).
  go_tree->get_expanded_nodes( CHANGING node_key_table = lt_expanded ).
  gv_status = |Selected nodes { lines( lt_selected ) }; expanded nodes { lines( lt_expanded ) }|.
ENDFORM.

FORM toggle_column.
  gv_hidden = xsdbool( gv_hidden = abap_false ).
  go_tree->column_set_hidden( column_name = 'STATE' hidden = gv_hidden ).
  go_tree->adjust_column_width( all_columns = abap_true include_heading = abap_true ).
  gv_status = |STATE column hidden: { gv_hidden }; visible columns optimized|.
ENDFORM.

FORM change_header.
  DATA lv_width TYPE i.

  gv_header_alt = xsdbool( gv_header_alt = abap_false ).
  go_tree->hierarchy_header_set_text(
    COND tv_heading( WHEN gv_header_alt = abap_true
      THEN 'Runtime hierarchy' ELSE 'Tree subject' ) ).
  go_tree->hierarchy_header_set_tooltip( 'Header text and width changed at runtime' ).
  go_tree->hierarchy_header_set_width(
    COND #( WHEN gv_header_alt = abap_true THEN 40 ELSE 30 ) ).
  go_tree->hierarchy_header_get_width( IMPORTING width = lv_width ).
  gv_status = |Hierarchy heading changed; reported width { lv_width }|.
ENDFORM.

FORM add_lazy_children.
  DATA lt_nodes TYPE ty_nodes.
  DATA lt_items TYPE ty_items.

  IF gv_lazy_loaded = abap_true.
    gv_status = 'Lazy children already loaded; duplicate insertion prevented'.
    RETURN.
  ENDIF.
  lt_nodes = VALUE #(
    ( node_key = 'LAZY_A' relatkey = 'LAZY'
      relatship = cl_gui_column_tree=>relat_last_child n_image = '@3Y@' )
    ( node_key = 'LAZY_B' relatkey = 'LAZY'
      relatship = cl_gui_column_tree=>relat_last_child n_image = '@3Y@' ) ).
  lt_items = VALUE #(
    ( node_key = 'LAZY_A' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'Loaded child A' )
    ( node_key = 'LAZY_A' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = 'Created in expand event' )
    ( node_key = 'LAZY_A' item_name = 'KIND' class = cl_gui_column_tree=>item_class_text text = 'text' )
    ( node_key = 'LAZY_A' item_name = 'STATE' class = cl_gui_column_tree=>item_class_text text = 'loaded' )
    ( node_key = 'LAZY_B' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'Loaded child B' )
    ( node_key = 'LAZY_B' item_name = 'NAME' class = cl_gui_column_tree=>item_class_link text = 'Second lazy result' )
    ( node_key = 'LAZY_B' item_name = 'KIND' class = cl_gui_column_tree=>item_class_text text = 'link' )
    ( node_key = 'LAZY_B' item_name = 'STATE' class = cl_gui_column_tree=>item_class_text text = 'loaded' ) ).
  go_tree->add_nodes_and_items(
    node_table = lt_nodes item_table = lt_items
    item_table_structure_name = 'MTREEITM' ).
  APPEND LINES OF lt_nodes TO gt_nodes.
  APPEND LINES OF lt_items TO gt_items.
  gv_lazy_loaded = abap_true.
  gv_status = 'Two children loaded only when LAZY was expanded'.
ENDFORM.

FORM audit_classes.
  DATA lt_names TYPE ty_class_names.
  DATA lv_available TYPE i.
  DATA lv_missing TYPE i.
  DATA lo_descr TYPE REF TO cl_abap_typedescr.

  lt_names = VALUE #(
    ( `CL_GUI_SIMPLE_TREE` ) ( `CL_GUI_LIST_TREE` ) ( `CL_GUI_COLUMN_TREE` )
    ( `CL_SIMPLE_TREE_MODEL` ) ( `CL_LIST_TREE_MODEL` ) ( `CL_COLUMN_TREE_MODEL` ) ).
  LOOP AT lt_names INTO DATA(lv_name).
    TRY.
        lo_descr = cl_abap_classdescr=>describe_by_name( lv_name ).
        ADD 1 TO lv_available.
      CATCH cx_root.
        ADD 1 TO lv_missing.
    ENDTRY.
  ENDLOOP.
  gv_status = |Tree family capability audit: { lv_available } classes available, { lv_missing } missing|.
  gv_event = 'The runnable view uses CL_GUI_COLUMN_TREE; model-specific samples remain separate work'.
ENDFORM.

FORM reset_tree.
  go_tree->delete_all_nodes( ).
  CLEAR: gv_sequence, gv_hidden, gv_moved, gv_lazy_loaded, gv_header_alt.
  PERFORM build_initial_data.
  PERFORM transfer_all_data.
  go_tree->column_set_hidden( column_name = 'STATE' hidden = abap_false ).
  go_tree->hierarchy_header_set_text( 'Tree subject' ).
  go_tree->hierarchy_header_set_width( 30 ).
  go_tree->expand_root_nodes( level_count = 2 ).
  gv_status = 'Tree nodes, items, columns, header, selection assumptions, and lazy state reset'.
ENDFORM.

FORM show_fallback USING io_error TYPE REF TO cx_root.
  DATA lt_text TYPE ty_text_lines.

  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( 'CL_GUI_COLUMN_TREE is unavailable or nonfunctional in this runtime.' )
    ( 'The native SAP sample remains syntax checked and guarded by a capability check.' )
    ( 'Use Audit classes to inspect the tree control and tree model family.' ) ).
  go_fallback->set_text_as_r3table( lt_text ).
  gv_status = 'Column tree unavailable; a non-terminating text fallback is displayed'.
  gv_event = io_error->get_text( ).
ENDFORM.

FORM free_controls.
  IF go_tree IS BOUND.
    TRY. go_tree->free( ). CATCH cx_root. ENDTRY.
    FREE go_tree.
  ENDIF.
  FREE go_events.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
