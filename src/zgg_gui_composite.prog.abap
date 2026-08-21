REPORT zgg_gui_composite.

CONSTANTS c_button TYPE i VALUE 0.
CONSTANTS c_separator TYPE i VALUE 3.

TYPES:
  BEGIN OF ty_row,
    id       TYPE c LENGTH 8,
    name     TYPE c LENGTH 30,
    category TYPE c LENGTH 18,
    quantity TYPE i,
    price    TYPE p LENGTH 8 DECIMALS 2,
    currency TYPE c LENGTH 3,
  END OF ty_row,
  ty_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.
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

CLASS lcl_payload DEFINITION FINAL.
  PUBLIC SECTION.
    DATA source TYPE c LENGTH 8 READ-ONLY.
    DATA row_index TYPE i READ-ONLY.
    DATA node_key TYPE tv_nodekey READ-ONLY.
    DATA id TYPE c LENGTH 8 READ-ONLY.
    DATA name TYPE c LENGTH 30 READ-ONLY.
    METHODS constructor IMPORTING iv_source TYPE c iv_row_index TYPE i OPTIONAL
      iv_node_key TYPE tv_nodekey OPTIONAL iv_id TYPE c OPTIONAL iv_name TYPE c OPTIONAL.
ENDCLASS.

CLASS lcl_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_tree_selection FOR EVENT selection_changed OF cl_gui_column_tree
      IMPORTING node_key.
    METHODS on_grid_double FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column es_row_no.
    METHODS on_toolbar FOR EVENT function_selected OF cl_gui_toolbar
      IMPORTING fcode.
    METHODS on_tree_drag FOR EVENT on_drag OF cl_gui_column_tree
      IMPORTING node_key item_name drag_drop_object.
    METHODS on_tree_drop FOR EVENT on_drop OF cl_gui_column_tree
      IMPORTING node_key drag_drop_object.
    METHODS on_grid_drag FOR EVENT ondrag OF cl_gui_alv_grid
      IMPORTING e_row e_column es_row_no e_dragdropobj.
    METHODS on_grid_drop FOR EVENT ondrop OF cl_gui_alv_grid
      IMPORTING e_row e_column es_row_no e_dragdropobj.
ENDCLASS.

DATA gt_all_rows TYPE ty_rows.
DATA gt_rows TYPE ty_rows.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA gt_nodes TYPE ty_nodes.
DATA gt_items TYPE ty_items.
DATA gt_log TYPE ty_text_lines.
DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_root_splitter TYPE REF TO cl_gui_splitter_container.
DATA go_right_splitter TYPE REF TO cl_gui_splitter_container.
DATA go_nav_host TYPE REF TO cl_gui_container.
DATA go_right_host TYPE REF TO cl_gui_container.
DATA go_toolbar_host TYPE REF TO cl_gui_container.
DATA go_grid_host TYPE REF TO cl_gui_container.
DATA go_detail_host TYPE REF TO cl_gui_container.
DATA go_tree TYPE REF TO cl_gui_column_tree.
DATA go_toolbar TYPE REF TO cl_gui_toolbar.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA go_details TYPE REF TO cl_gui_textedit.
DATA go_events TYPE REF TO lcl_events.
DATA go_dragdrop TYPE REF TO cl_dragdrop.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_drag_handle TYPE i.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_active TYPE c LENGTH 12 VALUE 'TREE'.
DATA gv_filter TYPE c LENGTH 18.
DATA gv_details_visible TYPE abap_bool VALUE abap_true.
DATA gv_layout_saved TYPE abap_bool.
DATA gv_saved_nav_width TYPE i VALUE 28.
DATA gv_saved_grid_height TYPE i VALUE 58.
DATA gv_saved_detail_height TYPE i VALUE 34.

CLASS lcl_payload IMPLEMENTATION.
  METHOD constructor.
    source = iv_source.
    row_index = iv_row_index.
    node_key = iv_node_key.
    id = iv_id.
    name = iv_name.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_tree_selection.
    gv_active = 'TREE'.
    PERFORM select_navigation USING node_key.
  ENDMETHOD.

  METHOD on_grid_double.
    gv_active = 'GRID'.
    DATA(lv_row) = es_row_no-row_id.
    PERFORM show_product USING lv_row.
    gv_status = |Grid double-click row { e_row-index }, column { e_column-fieldname }|.
    PERFORM add_log USING gv_status.
  ENDMETHOD.

  METHOD on_toolbar.
    PERFORM toolbar_action USING fcode.
  ENDMETHOD.

  METHOD on_tree_drag.
    IF node_key = 'ROOT' OR node_key = 'INPUT' OR node_key = 'DISPLAY'.
      drag_drop_object->abort( ).
      gv_status = |Folder { node_key } is a target, not a transferable item|.
      PERFORM add_log USING gv_status.
      RETURN.
    ENDIF.
    CREATE OBJECT drag_drop_object->object TYPE lcl_payload
      EXPORTING iv_source = 'TREE' iv_node_key = node_key
        iv_id = CONV char8( node_key ) iv_name = |Navigation item { node_key }|.
    drag_drop_object->effect = cl_dragdrop=>copy.
    gv_status = |Tree drag { node_key }/{ item_name } started|.
    PERFORM add_log USING gv_status.
  ENDMETHOD.

  METHOD on_tree_drop.
    DATA lo_payload TYPE REF TO lcl_payload.
    TRY.
        lo_payload ?= drag_drop_object->object.
        IF lo_payload->source <> 'GRID'.
          drag_drop_object->abort( ).
          gv_status = 'Composite tree accepts grid product payloads only'.
        ELSE.
          READ TABLE gt_all_rows WITH KEY id = lo_payload->id ASSIGNING FIELD-SYMBOL(<row>).
          IF sy-subrc <> 0. RAISE EXCEPTION TYPE cx_sy_itab_line_not_found. ENDIF.
          <row>-category = COND #( WHEN node_key = 'DISPLAY' THEN 'Display' ELSE 'Input' ).
          PERFORM select_navigation USING node_key.
          gv_status = |Grid product { lo_payload->id } assigned through drop to { <row>-category }|.
          drag_drop_object->effect = cl_dragdrop=>move.
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        drag_drop_object->abort( ).
        gv_status = |Tree drop aborted: { lx_error->get_text( ) }|.
    ENDTRY.
    PERFORM add_log USING gv_status.
  ENDMETHOD.

  METHOD on_grid_drag.
    READ TABLE gt_rows INDEX es_row_no-row_id INTO DATA(ls_row).
    IF sy-subrc <> 0.
      e_dragdropobj->abort( ).
      RETURN.
    ENDIF.
    CREATE OBJECT e_dragdropobj->object TYPE lcl_payload
      EXPORTING iv_source = 'GRID' iv_row_index = es_row_no-row_id
        iv_id = ls_row-id iv_name = ls_row-name.
    e_dragdropobj->effect = cl_dragdrop=>move.
    gv_status = |Grid drag { ls_row-id }, row { e_row-index }, column { e_column-fieldname }|.
    PERFORM add_log USING gv_status.
  ENDMETHOD.

  METHOD on_grid_drop.
    DATA lo_payload TYPE REF TO lcl_payload.
    TRY.
        lo_payload ?= e_dragdropobj->object.
        IF lo_payload->source = 'TREE'.
          APPEND VALUE #( id = lo_payload->id name = lo_payload->name
            category = 'Navigation' quantity = 1 price = '1.00' currency = 'EUR' ) TO gt_all_rows.
          gv_filter = space.
          gt_rows = gt_all_rows.
          go_grid->refresh_table_display(
            is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
          gv_status = |Tree item { lo_payload->node_key } copied into grid at row { lines( gt_rows ) }|.
        ELSE.
          READ TABLE gt_rows INDEX lo_payload->row_index INTO DATA(ls_row).
          IF sy-subrc <> 0. RAISE EXCEPTION TYPE cx_sy_itab_line_not_found. ENDIF.
          DELETE gt_rows INDEX lo_payload->row_index.
          DATA(lv_target) = COND i( WHEN es_row_no-row_id > lines( gt_rows )
            THEN lines( gt_rows ) + 1 ELSE es_row_no-row_id ).
          INSERT ls_row INTO gt_rows INDEX lv_target.
          go_grid->refresh_table_display(
            is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
          gv_status = |Grid row reordered to target { lv_target }, column { e_column-fieldname }, displayed row { e_row-index }|.
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        e_dragdropobj->abort( ).
        gv_status = |Grid drop aborted: { lx_error->get_text( ) }|.
    ENDTRY.
    PERFORM add_log USING gv_status.
    PERFORM refresh_details.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_controls.
ENDMODULE.

MODULE dispatch_0100 INPUT.
  DATA lv_return_code TYPE i.
  IF go_tree IS BOUND OR go_grid IS BOUND OR go_toolbar IS BOUND.
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
  CASE lv_ok_code.
    WHEN 'SAVE'.
      PERFORM save_layout.
    WHEN 'RESTORE'.
      PERFORM restore_layout.
    WHEN 'RESET'.
      PERFORM reset_workbench.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  DATA ls_header TYPE treev_hhdr.
  DATA lt_events TYPE cntl_simple_events.

  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  IF go_grid IS BOUND OR go_fallback IS BOUND.
    RETURN.
  ENDIF.
  PERFORM build_data.
  TRY.
      CREATE OBJECT go_root_splitter EXPORTING parent = go_host rows = 1 columns = 2.
      go_root_splitter->get_container( EXPORTING row = 1 column = 1 RECEIVING container = go_nav_host ).
      go_root_splitter->get_container( EXPORTING row = 1 column = 2 RECEIVING container = go_right_host ).
      go_root_splitter->set_column_width( id = 1 width = 28 ).
      CREATE OBJECT go_right_splitter EXPORTING parent = go_right_host rows = 3 columns = 1.
      go_right_splitter->get_container( EXPORTING row = 1 column = 1 RECEIVING container = go_toolbar_host ).
      go_right_splitter->get_container( EXPORTING row = 2 column = 1 RECEIVING container = go_grid_host ).
      go_right_splitter->get_container( EXPORTING row = 3 column = 1 RECEIVING container = go_detail_host ).
      go_right_splitter->set_row_height( id = 1 height = 8 ).
      go_right_splitter->set_row_height( id = 2 height = 58 ).
      go_right_splitter->set_row_height( id = 3 height = 34 ).
      PERFORM configure_dragdrop.
      ls_header = VALUE #( heading = 'Navigation' width = 28 tooltip = 'Select a category or drag products' ).
      CREATE OBJECT go_tree EXPORTING parent = go_nav_host
        node_selection_mode = cl_gui_column_tree=>node_sel_mode_single
        item_selection = abap_true hierarchy_column_name = 'NODE'
        hierarchy_header = ls_header.
      go_tree->add_column( name = 'NAME' width = 20 header_text = 'Scope' ).
      CREATE OBJECT go_toolbar EXPORTING parent = go_toolbar_host
        display_mode                            = cl_gui_toolbar=>m_mode_horizontal.
      CREATE OBJECT go_grid EXPORTING i_parent = go_grid_host.
      CREATE OBJECT go_details EXPORTING parent = go_detail_host.
      CREATE OBJECT go_events.
      SET HANDLER go_events->on_tree_selection FOR go_tree.
      SET HANDLER go_events->on_grid_double FOR go_grid.
      SET HANDLER go_events->on_toolbar FOR go_toolbar.
      SET HANDLER go_events->on_tree_drag FOR go_tree.
      SET HANDLER go_events->on_tree_drop FOR go_tree.
      SET HANDLER go_events->on_grid_drag FOR go_grid.
      SET HANDLER go_events->on_grid_drop FOR go_grid.
      lt_events = VALUE #( ( eventid = cl_gui_column_tree=>eventid_selection_changed appl_event = abap_true ) ).
      go_tree->set_registered_events( events = lt_events ).
      lt_events = VALUE #( ( eventid = cl_gui_toolbar=>m_id_function_selected appl_event = abap_true ) ).
      go_toolbar->set_registered_events( events = lt_events ).
      PERFORM populate_tree.
      PERFORM populate_toolbar.
      go_grid->set_table_for_first_display(
        EXPORTING is_layout = VALUE lvc_s_layo( zebra = abap_true grid_title = 'Products in active navigation scope' )
        CHANGING it_outtab = gt_rows it_fieldcatalog = gt_fieldcat ).
      go_details->set_readonly_mode( readonly_mode = 1 ).
      go_tree->expand_root_nodes( level_count = 3 ).
      gv_status = 'Workbench ready: select navigation, inspect grid rows, use toolbar commands, or drag between panes'.
      PERFORM add_log USING gv_status.
      PERFORM refresh_details.
    CATCH cx_root INTO DATA(lx_error).
      PERFORM show_fallback USING lx_error.
  ENDTRY.
ENDFORM.

FORM configure_dragdrop.
  CREATE OBJECT go_dragdrop.
  go_dragdrop->add( flavor = 'GG_COMPOSITE' dragsrc = abap_true droptarget = abap_true
    effect = cl_dragdrop=>move effect_in_ctrl = cl_dragdrop=>move ).
  go_dragdrop->get_handle( IMPORTING handle = gv_drag_handle ).
ENDFORM.

FORM build_data.
  gt_all_rows = VALUE #(
    ( id = 'P100' name = 'Mechanical Keyboard' category = 'Input' quantity = 12 price = '129.90' currency = 'EUR' )
    ( id = 'P110' name = 'Ergonomic Mouse' category = 'Input' quantity = 7 price = '74.50' currency = 'EUR' )
    ( id = 'P200' name = '27 Inch Display' category = 'Display' quantity = 4 price = '389.00' currency = 'EUR' ) ).
  gt_rows = gt_all_rows.
  gt_fieldcat = VALUE #(
    ( fieldname = 'ID' col_pos = 1 coltext = 'ID' key = abap_true outputlen = 9 dragdropid = gv_drag_handle )
    ( fieldname = 'NAME' col_pos = 2 coltext = 'Product' outputlen = 28 dragdropid = gv_drag_handle )
    ( fieldname = 'CATEGORY' col_pos = 3 coltext = 'Category' outputlen = 16 dragdropid = gv_drag_handle )
    ( fieldname = 'QUANTITY' col_pos = 4 coltext = 'Quantity' outputlen = 10 dragdropid = gv_drag_handle )
    ( fieldname = 'PRICE' col_pos = 5 coltext = 'Price' cfieldname = 'CURRENCY' outputlen = 14 dragdropid = gv_drag_handle )
    ( fieldname = 'CURRENCY' col_pos = 6 coltext = 'Currency' outputlen = 8 dragdropid = gv_drag_handle ) ).
ENDFORM.

FORM populate_tree.
  gt_nodes = VALUE #(
    ( node_key = 'ROOT' isfolder = abap_true n_image = '@04@' exp_image = '@05@' dragdropid = gv_drag_handle )
    ( node_key = 'INPUT' relatkey = 'ROOT' relatship = cl_gui_column_tree=>relat_last_child
      isfolder = abap_true n_image = '@3Y@' dragdropid = gv_drag_handle )
    ( node_key = 'DISPLAY' relatkey = 'ROOT' relatship = cl_gui_column_tree=>relat_last_child
      isfolder = abap_true n_image = '@3Y@' dragdropid = gv_drag_handle )
    ( node_key = 'P100' relatkey = 'INPUT' relatship = cl_gui_column_tree=>relat_last_child dragdropid = gv_drag_handle )
    ( node_key = 'P110' relatkey = 'INPUT' relatship = cl_gui_column_tree=>relat_last_child dragdropid = gv_drag_handle )
    ( node_key = 'P200' relatkey = 'DISPLAY' relatship = cl_gui_column_tree=>relat_last_child dragdropid = gv_drag_handle ) ).
  gt_items = VALUE #(
    ( node_key = 'ROOT' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'All products' )
    ( node_key = 'ROOT' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = '3 rows' )
    ( node_key = 'INPUT' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'Input devices' )
    ( node_key = 'INPUT' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = '2 rows' )
    ( node_key = 'DISPLAY' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'Displays' )
    ( node_key = 'DISPLAY' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = '1 row' )
    ( node_key = 'P100' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'P100' )
    ( node_key = 'P100' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = 'Keyboard' )
    ( node_key = 'P110' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'P110' )
    ( node_key = 'P110' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = 'Mouse' )
    ( node_key = 'P200' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'P200' )
    ( node_key = 'P200' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = 'Display' ) ).
  go_tree->add_nodes_and_items( node_table = gt_nodes item_table = gt_items
    item_table_structure_name = 'MTREEITM' ).
ENDFORM.

FORM populate_toolbar.
  go_toolbar->add_button( fcode = 'TREE' icon = '@3P@' butn_type = c_button
    text = 'Tree' quickinfo = 'Activate navigation tree' ).
  go_toolbar->add_button( fcode = 'GRID' icon = '@3Y@' butn_type = c_button
    text = 'Grid' quickinfo = 'Make the ALV grid active' ).
  go_toolbar->add_button( fcode = 'DETAIL' icon = '@0S@' butn_type = c_button
    text = 'Details' quickinfo = 'Make the detail editor active' ).
  go_toolbar->add_button( fcode = '' icon = '' butn_type = c_separator ).
  go_toolbar->add_button( fcode = 'REFRESH' icon = '@42@' butn_type = c_button
    text = 'Refresh' quickinfo = 'Refresh active child control' ).
  go_toolbar->add_button( fcode = 'TOGGLE' icon = '@3Z@' butn_type = c_button
    text = 'Details pane' quickinfo = 'Show or hide detail pane' ).
  go_toolbar->add_button( fcode = 'RESET' icon = '@18@' butn_type = c_button
    text = 'Reset' quickinfo = 'Reset data, filters, and panes' ).
ENDFORM.

FORM select_navigation USING iv_node TYPE tv_nodekey.
  IF iv_node = 'INPUT'.
    gv_filter = 'Input'.
  ELSEIF iv_node = 'DISPLAY'.
    gv_filter = 'Display'.
  ELSEIF iv_node = 'ROOT'.
    CLEAR gv_filter.
  ELSE.
    READ TABLE gt_all_rows WITH KEY id = iv_node INTO DATA(ls_product).
    IF sy-subrc = 0.
      gv_filter = ls_product-category.
      gt_rows = VALUE #( ( ls_product ) ).
      PERFORM show_row_detail USING ls_product.
      go_grid->refresh_table_display(
        is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
      gv_status = |Navigation leaf { iv_node } selected; one matching product shown|.
      PERFORM add_log USING gv_status.
      RETURN.
    ENDIF.
  ENDIF.
  CLEAR gt_rows.
  LOOP AT gt_all_rows INTO DATA(ls_row).
    IF gv_filter IS INITIAL OR ls_row-category = gv_filter. APPEND ls_row TO gt_rows. ENDIF.
  ENDLOOP.
  IF go_grid IS BOUND.
    go_grid->refresh_table_display(
      is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
  ENDIF.
  gv_status = |Navigation { iv_node } selected; grid rows { lines( gt_rows ) }, filter { gv_filter }|.
  PERFORM add_log USING gv_status.
  PERFORM refresh_details.
ENDFORM.

FORM show_product USING iv_index TYPE i.
  READ TABLE gt_rows INDEX iv_index INTO DATA(ls_row).
  IF sy-subrc = 0. PERFORM show_row_detail USING ls_row. ENDIF.
ENDFORM.

FORM show_row_detail USING is_row TYPE ty_row.
  gv_detail = |{ is_row-id } { is_row-name }; { is_row-category }; quantity { is_row-quantity }; { is_row-price } { is_row-currency }|.
  PERFORM refresh_details.
ENDFORM.

FORM toolbar_action USING iv_fcode TYPE sy-ucomm.
  CASE iv_fcode.
    WHEN 'TREE' OR 'GRID' OR 'DETAIL'.
      gv_active = iv_fcode.
      gv_status = |Toolbar changed active child to { gv_active }|.
    WHEN 'REFRESH'.
      IF gv_active = 'GRID' AND go_grid IS BOUND.
        go_grid->refresh_table_display(
          is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
      ELSEIF gv_active = 'TREE' AND go_tree IS BOUND.
        go_tree->expand_root_nodes( level_count = 3 ).
      ELSE.
        PERFORM refresh_details.
      ENDIF.
      gv_status = |Toolbar refreshed active child { gv_active }|.
    WHEN 'TOGGLE'.
      gv_details_visible = xsdbool( gv_details_visible = abap_false ).
      go_right_splitter->set_row_height( id = 3
        height                              = COND #( WHEN gv_details_visible = abap_true THEN 34 ELSE 0 ) ).
      gv_status = |Toolbar detail-pane visibility { gv_details_visible }|.
    WHEN 'RESET'.
      PERFORM reset_workbench.
      RETURN.
  ENDCASE.
  PERFORM add_log USING gv_status.
  PERFORM refresh_details.
ENDFORM.

FORM add_log USING iv_text TYPE c.
  INSERT CONV ty_text_line( |{ sy-uzeit TIME = USER }  { iv_text }| ) INTO gt_log INDEX 1.
  IF lines( gt_log ) > 12. DELETE gt_log INDEX 13. ENDIF.
ENDFORM.

FORM refresh_details.
  DATA lt_text TYPE ty_text_lines.

  IF go_details IS NOT BOUND. RETURN. ENDIF.
  lt_text = VALUE #(
    ( |Active child: { gv_active }; navigation filter: { gv_filter }; visible grid rows: { lines( gt_rows ) }| )
    ( |Detail: { gv_detail }| )
    ( 'Recent events' ) ).
  APPEND LINES OF gt_log TO lt_text.
  go_details->set_text_as_r3table( table = lt_text ).
ENDFORM.

FORM save_layout.
  TRY.
      CALL METHOD go_root_splitter->('GET_COLUMN_WIDTH')
        EXPORTING id = 1 IMPORTING result = gv_saved_nav_width.
      go_right_splitter->get_row_height( EXPORTING id = 2 IMPORTING result = gv_saved_grid_height ).
      go_right_splitter->get_row_height( EXPORTING id = 3 IMPORTING result = gv_saved_detail_height ).
      gv_layout_saved = abap_true.
      gv_status = |Session layout saved: navigation { gv_saved_nav_width }, grid { gv_saved_grid_height }, details { gv_saved_detail_height }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Splitter size query unavailable: { lx_error->get_text( ) }|.
  ENDTRY.
  PERFORM add_log USING gv_status.
  PERFORM refresh_details.
ENDFORM.

FORM restore_layout.
  IF gv_layout_saved = abap_false.
    gv_status = 'No session layout has been saved'.
  ELSE.
    go_root_splitter->set_column_width( id = 1 width = gv_saved_nav_width ).
    go_right_splitter->set_row_height( id = 2 height = gv_saved_grid_height ).
    go_right_splitter->set_row_height( id = 3 height = gv_saved_detail_height ).
    gv_details_visible = xsdbool( gv_saved_detail_height > 0 ).
    gv_status = 'Saved splitter proportions restored for the current report session'.
  ENDIF.
  PERFORM add_log USING gv_status.
  PERFORM refresh_details.
ENDFORM.

FORM reset_workbench.
  PERFORM build_data.
  CLEAR: gv_filter, gv_detail, gt_log.
  gv_active = 'TREE'.
  gv_details_visible = abap_true.
  go_root_splitter->set_column_width( id = 1 width = 28 ).
  go_right_splitter->set_row_height( id = 1 height = 8 ).
  go_right_splitter->set_row_height( id = 2 height = 58 ).
  go_right_splitter->set_row_height( id = 3 height = 34 ).
  go_grid->refresh_table_display(
    is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
  gv_status = 'Workbench data, active child, filter, event log, and default splitter proportions reset'.
  PERFORM add_log USING gv_status.
  PERFORM refresh_details.
ENDFORM.

FORM show_fallback USING io_error TYPE REF TO cx_root.
  DATA lt_text TYPE ty_text_lines.

  FREE: go_tree, go_toolbar, go_grid, go_details, go_events, go_dragdrop,
    go_right_splitter, go_root_splitter.
  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( 'The composed workbench controls are unavailable in this runtime.' )
    ( 'The native report retains nested splitters, navigation, toolbar, grid, details, coordinated events, drag/drop, and session layout state.' )
    ( 'The pinned open-abap hosted controls currently terminate in runtime assertions.' ) ).
  go_fallback->set_text_as_r3table( table = lt_text ).
  go_fallback->set_readonly_mode( readonly_mode = 1 ).
  gv_status = 'Composite workbench unavailable; diagnostic fallback shown'.
  gv_detail = io_error->get_text( ).
ENDFORM.

FORM free_controls.
  FREE: go_events, go_dragdrop.
  IF go_tree IS BOUND. go_tree->free( ). FREE go_tree. ENDIF.
  IF go_toolbar IS BOUND. go_toolbar->free( ). FREE go_toolbar. ENDIF.
  IF go_grid IS BOUND. go_grid->free( ). FREE go_grid. ENDIF.
  IF go_details IS BOUND. go_details->free( ). FREE go_details. ENDIF.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_right_splitter IS BOUND. go_right_splitter->free( ). FREE go_right_splitter. ENDIF.
  IF go_root_splitter IS BOUND. go_root_splitter->free( ). FREE go_root_splitter. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
