REPORT zgg_gui_drag_drop.

TYPES:
  BEGIN OF ty_row,
    id       TYPE c LENGTH 8,
    name     TYPE c LENGTH 30,
    category TYPE c LENGTH 18,
    quantity TYPE i,
  END OF ty_row,
  ty_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.
TYPES ty_nodes TYPE treev_ntab.
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

CLASS lcl_drag_payload DEFINITION FINAL.
  PUBLIC SECTION.
    DATA source TYPE c LENGTH 8 READ-ONLY.
    DATA row_index TYPE i READ-ONLY.
    DATA node_key TYPE tv_nodekey READ-ONLY.
    DATA node_keys TYPE treev_nks READ-ONLY.
    DATA id TYPE c LENGTH 8 READ-ONLY.
    DATA name TYPE c LENGTH 30 READ-ONLY.
    METHODS constructor
      IMPORTING iv_source TYPE c iv_row_index TYPE i OPTIONAL
        iv_node_key TYPE tv_nodekey OPTIONAL iv_id TYPE c OPTIONAL
        iv_name TYPE c OPTIONAL it_node_keys TYPE treev_nks OPTIONAL.
ENDCLASS.

CLASS lcl_log DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS add IMPORTING iv_event TYPE string.
ENDCLASS.

CLASS lcl_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_grid_drag FOR EVENT ondrag OF cl_gui_alv_grid
      IMPORTING e_row e_column es_row_no e_dragdropobj.
    METHODS on_grid_drop FOR EVENT ondrop OF cl_gui_alv_grid
      IMPORTING e_row e_column es_row_no e_dragdropobj.
    METHODS on_grid_complete FOR EVENT ondropcomplete OF cl_gui_alv_grid
      IMPORTING e_row e_column es_row_no e_dragdropobj.
    METHODS on_grid_flavor FOR EVENT ondropgetflavor OF cl_gui_alv_grid
      IMPORTING e_row e_column es_row_no e_dragdropobj e_flavors.
    METHODS on_tree_drag FOR EVENT on_drag OF cl_gui_column_tree
      IMPORTING node_key item_name drag_drop_object.
    METHODS on_tree_drag_multiple FOR EVENT on_drag_multiple OF cl_gui_column_tree
      IMPORTING node_key_table item_name drag_drop_object.
    METHODS on_tree_drop FOR EVENT on_drop OF cl_gui_column_tree
      IMPORTING node_key drag_drop_object.
    METHODS on_tree_complete FOR EVENT on_drop_complete OF cl_gui_column_tree
      IMPORTING node_key item_name drag_drop_object.
    METHODS on_tree_flavor FOR EVENT on_drop_get_flavor OF cl_gui_column_tree
      IMPORTING node_key flavors drag_drop_object.
ENDCLASS.

DATA gt_rows TYPE ty_rows.
DATA gt_rows_undo TYPE ty_rows.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA gt_nodes TYPE ty_nodes.
DATA gt_items TYPE ty_items.
DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_splitter TYPE REF TO cl_gui_splitter_container.
DATA go_tree_host TYPE REF TO cl_gui_container.
DATA go_grid_host TYPE REF TO cl_gui_container.
DATA go_tree TYPE REF TO cl_gui_column_tree.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA go_events TYPE REF TO lcl_events.
DATA go_dragdrop TYPE REF TO cl_dragdrop.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_handle TYPE i.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_event_count TYPE i.
DATA gv_accept_drop TYPE abap_bool VALUE abap_true.
DATA gv_last_action TYPE c LENGTH 12.
DATA gv_last_node TYPE tv_nodekey.
DATA gv_last_parent TYPE tv_nodekey.
DATA gt_last_nodes TYPE treev_nks.
DATA gv_added_node TYPE tv_nodekey.
DATA gv_sequence TYPE i VALUE 900.

CLASS lcl_drag_payload IMPLEMENTATION.
  METHOD constructor.
    source = iv_source.
    row_index = iv_row_index.
    node_key = iv_node_key.
    node_keys = it_node_keys.
    id = iv_id.
    name = iv_name.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_log IMPLEMENTATION.
  METHOD add.
    ADD 1 TO gv_event_count.
    gv_status = |{ gv_event_count }: { iv_event }|.
    IF strlen( gv_status ) > 108. gv_status = gv_status(108). ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_grid_drag.
    READ TABLE gt_rows INDEX es_row_no-row_id INTO DATA(ls_row).
    IF sy-subrc <> 0.
      e_dragdropobj->abort( ).
      lcl_log=>add( 'GRID drag aborted: source row is invalid' ).
      RETURN.
    ENDIF.
    CREATE OBJECT e_dragdropobj->object TYPE lcl_drag_payload
      EXPORTING iv_source    = 'GRID'
                iv_row_index = es_row_no-row_id
        iv_id                = ls_row-id
                iv_name      = ls_row-name.
    e_dragdropobj->effect = cl_dragdrop=>move.
    lcl_log=>add( |GRID drag row { e_row-index }, column { e_column-fieldname }, flavor GG_ITEMS| ).
  ENDMETHOD.

  METHOD on_grid_drop.
    DATA lo_payload TYPE REF TO lcl_drag_payload.

    IF gv_accept_drop = abap_false.
      e_dragdropobj->abort( ).
      gv_accept_drop = abap_true.
      lcl_log=>add( 'GRID drop rejected by the Reject next switch' ).
      RETURN.
    ENDIF.
    TRY.
        lo_payload ?= e_dragdropobj->object.
        gt_rows_undo = gt_rows.
        IF lo_payload->source = 'GRID'.
          READ TABLE gt_rows INDEX lo_payload->row_index INTO DATA(ls_row).
          IF sy-subrc <> 0. RAISE EXCEPTION TYPE cx_sy_itab_line_not_found. ENDIF.
          DELETE gt_rows INDEX lo_payload->row_index.
          DATA(lv_target) = COND i( WHEN es_row_no-row_id > lines( gt_rows )
            THEN lines( gt_rows ) + 1 ELSE es_row_no-row_id ).
          INSERT ls_row INTO gt_rows INDEX lv_target.
          gv_last_action = 'GRID'.
          lcl_log=>add( |GRID accepted row { lo_payload->row_index } at target { lv_target }| ).
        ELSEIF lo_payload->source = 'TREE'.
          IF lo_payload->node_keys IS INITIAL.
            APPEND VALUE #( id = lo_payload->id name = lo_payload->name
              category = 'From tree' quantity = 1 ) TO gt_rows.
          ELSE.
            LOOP AT lo_payload->node_keys INTO DATA(lv_key).
              APPEND VALUE #( id = CONV #( lv_key ) name = |Tree item { lv_key }|
                category = 'From tree' quantity = 1 ) TO gt_rows.
            ENDLOOP.
          ENDIF.
          gv_last_action = 'GRID'.
          lcl_log=>add( |TREE to GRID accepted; node count { COND i( WHEN lo_payload->node_keys IS INITIAL THEN 1 ELSE lines( lo_payload->node_keys ) ) }, final row { lines( gt_rows ) }| ).
        ELSE.
          RAISE EXCEPTION TYPE cx_sy_move_cast_error.
        ENDIF.
        go_grid->refresh_table_display(
          is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
        gv_detail = |Target row { e_row-index }, column { e_column-fieldname }; effect MOVE|.
      CATCH cx_root INTO DATA(lx_error).
        e_dragdropobj->abort( ).
        lcl_log=>add( |GRID drop aborted: { lx_error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD on_grid_complete.
    lcl_log=>add( |GRID complete row { e_row-index }/{ es_row_no-row_id }, { e_column-fieldname }, state { e_dragdropobj->state }| ).
  ENDMETHOD.

  METHOD on_grid_flavor.
    lcl_log=>add( |GRID flavor query { concat_lines_of( table = e_flavors
                                                        sep   = ',' ) } at row { e_row-index }/{ es_row_no-row_id }, { e_column-fieldname }| ).
    gv_detail = |Payload bound { xsdbool( e_dragdropobj IS BOUND ) }|.
  ENDMETHOD.

  METHOD on_tree_drag.
    IF node_key = 'ROOT' OR node_key = 'INPUT' OR node_key = 'DISPLAY'.
      drag_drop_object->abort( ).
      lcl_log=>add( |TREE drag rejected for folder { node_key }| ).
      RETURN.
    ENDIF.
    DATA(lv_id) = CONV char8( node_key ).
    CREATE OBJECT drag_drop_object->object TYPE lcl_drag_payload
      EXPORTING iv_source   = 'TREE'
                iv_node_key = node_key
        iv_id               = lv_id
                iv_name     = |Tree item { node_key }|.
    drag_drop_object->effect = cl_dragdrop=>move.
    lcl_log=>add( |TREE drag { node_key }/{ item_name }, flavor GG_ITEMS| ).
  ENDMETHOD.

  METHOD on_tree_drag_multiple.
    LOOP AT node_key_table INTO DATA(lv_key).
      IF lv_key = 'ROOT' OR lv_key = 'INPUT' OR lv_key = 'DISPLAY'.
        drag_drop_object->abort( ).
        lcl_log=>add( |TREE multi-drag rejected because selection contains folder { lv_key }| ).
        RETURN.
      ENDIF.
    ENDLOOP.
    READ TABLE node_key_table INDEX 1 INTO DATA(lv_first).
    CREATE OBJECT drag_drop_object->object TYPE lcl_drag_payload
      EXPORTING iv_source   = 'TREE'
                iv_node_key = lv_first
        iv_id               = CONV char8( lv_first )
                iv_name     = |Tree item { lv_first }|
        it_node_keys        = node_key_table.
    drag_drop_object->effect = cl_dragdrop=>move.
    lcl_log=>add( |TREE multi-drag { lines( node_key_table ) } nodes/{ item_name }, flavor GG_ITEMS| ).
  ENDMETHOD.

  METHOD on_tree_drop.
    DATA lo_payload TYPE REF TO lcl_drag_payload.

    IF gv_accept_drop = abap_false.
      drag_drop_object->abort( ).
      gv_accept_drop = abap_true.
      lcl_log=>add( 'TREE drop rejected by the Reject next switch' ).
      RETURN.
    ENDIF.
    TRY.
        lo_payload ?= drag_drop_object->object.
        IF lo_payload->source = 'TREE'.
          gv_last_node = lo_payload->node_key.
          gv_last_parent = COND #( WHEN lo_payload->node_key = 'P100' THEN 'INPUT' ELSE 'DISPLAY' ).
          CLEAR gt_last_nodes.
          IF lo_payload->node_keys IS INITIAL.
            APPEND lo_payload->node_key TO gt_last_nodes.
          ELSE.
            gt_last_nodes = lo_payload->node_keys.
          ENDIF.
          IF lo_payload->node_keys IS INITIAL.
            go_tree->move_node(
              node_key  = lo_payload->node_key
              relatkey  = node_key
              relatship = cl_gui_column_tree=>relat_last_child ).
          ELSE.
            LOOP AT lo_payload->node_keys INTO DATA(lv_key).
              go_tree->move_node(
                node_key  = lv_key
                relatkey  = node_key
                relatship = cl_gui_column_tree=>relat_last_child ).
            ENDLOOP.
          ENDIF.
          gv_last_action = 'TREE'.
          lcl_log=>add( |TREE accepted reparent; node count { COND i( WHEN lo_payload->node_keys IS INITIAL THEN 1 ELSE lines( lo_payload->node_keys ) ) } -> { node_key }| ).
        ELSEIF lo_payload->source = 'GRID'.
          PERFORM add_grid_item_to_tree USING node_key lo_payload->id lo_payload->name.
          gv_last_action = 'ADDNODE'.
          lcl_log=>add( |GRID to TREE accepted: { lo_payload->id } -> { node_key }| ).
        ELSE.
          RAISE EXCEPTION TYPE cx_sy_move_cast_error.
        ENDIF.
        drag_drop_object->effect = cl_dragdrop=>move.
      CATCH cx_root INTO DATA(lx_error).
        drag_drop_object->abort( ).
        lcl_log=>add( |TREE drop aborted: { lx_error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD on_tree_complete.
    lcl_log=>add( |TREE complete { node_key }/{ item_name }, state { drag_drop_object->state }| ).
  ENDMETHOD.

  METHOD on_tree_flavor.
    lcl_log=>add( |TREE flavor query returned { lines( flavors ) } entries at node { node_key }| ).
    gv_detail = |Payload bound { xsdbool( drag_drop_object IS BOUND ) }|.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_controls.
ENDMODULE.

MODULE dispatch_0100 INPUT.
  DATA lv_return_code TYPE i.
  IF go_tree IS BOUND OR go_grid IS BOUND.
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
    WHEN 'REJECT'.
      gv_accept_drop = abap_false.
      lcl_log=>add( 'The next tree or grid drop will be rejected and aborted' ).
    WHEN 'UNDO'.
      PERFORM undo_last_drop.
    WHEN 'SIMULATE'.
      PERFORM simulate_payload.
    WHEN 'RESET'.
      PERFORM reset_demo.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  DATA ls_header TYPE treev_hhdr.

  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  IF go_grid IS BOUND OR go_fallback IS BOUND.
    RETURN.
  ENDIF.
  PERFORM build_data.
  TRY.
      CREATE OBJECT go_splitter EXPORTING parent  = go_host
                                          rows    = 1
                                          columns = 2.
      go_splitter->get_container( EXPORTING row = 1
                                            column = 1 RECEIVING container = go_tree_host ).
      go_splitter->get_container( EXPORTING row = 1
                                            column = 2 RECEIVING container = go_grid_host ).
      go_splitter->set_column_width( id    = 1
                                     width = 38 ).
      PERFORM configure_behaviors.
      ls_header = VALUE #( heading = 'Drop target hierarchy' width = 28
        tooltip = 'Drag leaf nodes or drop grid rows on a target node' ).
      CREATE OBJECT go_tree EXPORTING parent                = go_tree_host
        node_selection_mode                                 = cl_gui_column_tree=>node_sel_mode_multiple
        item_selection                                      = abap_true
                                      hierarchy_column_name = 'NODE'
        hierarchy_header                                    = ls_header.
      go_tree->add_column( name        = 'NAME'
                           width       = 24
                           header_text = 'Payload' ).
      CREATE OBJECT go_grid EXPORTING i_parent = go_grid_host.
      CREATE OBJECT go_events.
      SET HANDLER go_events->on_grid_drag FOR go_grid.
      SET HANDLER go_events->on_grid_drop FOR go_grid.
      SET HANDLER go_events->on_grid_complete FOR go_grid.
      SET HANDLER go_events->on_grid_flavor FOR go_grid.
      SET HANDLER go_events->on_tree_drag FOR go_tree.
      SET HANDLER go_events->on_tree_drag_multiple FOR go_tree.
      SET HANDLER go_events->on_tree_drop FOR go_tree.
      SET HANDLER go_events->on_tree_complete FOR go_tree.
      SET HANDLER go_events->on_tree_flavor FOR go_tree.
      PERFORM transfer_tree.
      go_tree->expand_root_nodes( level_count = 3 ).
      go_grid->set_table_for_first_display(
        EXPORTING is_layout = VALUE lvc_s_layo( zebra = abap_true grid_title = 'Drag rows within the grid or into the tree' )
        CHANGING it_outtab = gt_rows it_fieldcatalog = gt_fieldcat ).
      lcl_log=>add( |Ready: behavior handle { gv_handle }, flavor GG_ITEMS, effect MOVE| ).
    CATCH cx_root INTO DATA(lx_error).
      PERFORM show_fallback USING lx_error.
  ENDTRY.
ENDFORM.

FORM configure_behaviors.
  CREATE OBJECT go_dragdrop.
  go_dragdrop->add( flavor         = 'GG_ITEMS'
                    dragsrc        = abap_true
                    droptarget     = abap_true
    effect                         = cl_dragdrop=>move
                    effect_in_ctrl = cl_dragdrop=>move ).
  go_dragdrop->add( flavor         = 'GG_COPY'
                    dragsrc        = abap_true
                    droptarget     = abap_true
    effect                         = cl_dragdrop=>copy
                    effect_in_ctrl = cl_dragdrop=>copy ).
  go_dragdrop->get_handle( IMPORTING handle = gv_handle ).
ENDFORM.

FORM build_data.
  gt_rows = VALUE #(
    ( id = 'P100' name = 'Mechanical Keyboard' category = 'Input' quantity = 12 )
    ( id = 'P110' name = 'Ergonomic Mouse' category = 'Input' quantity = 7 )
    ( id = 'P200' name = '27 Inch Display' category = 'Display' quantity = 4 ) ).
  gt_rows_undo = gt_rows.
  gt_fieldcat = VALUE #(
    ( fieldname = 'ID' col_pos = 1 coltext = 'ID' key = abap_true outputlen = 9 dragdropid = gv_handle )
    ( fieldname = 'NAME' col_pos = 2 coltext = 'Product' outputlen = 28 dragdropid = gv_handle )
    ( fieldname = 'CATEGORY' col_pos = 3 coltext = 'Category' outputlen = 16 dragdropid = gv_handle )
    ( fieldname = 'QUANTITY' col_pos = 4 coltext = 'Quantity' outputlen = 10 dragdropid = gv_handle ) ).
  gt_nodes = VALUE #(
    ( node_key = 'ROOT' isfolder = abap_true n_image = '@04@' exp_image = '@05@' dragdropid = gv_handle )
    ( node_key = 'INPUT' relatkey = 'ROOT' relatship = cl_gui_column_tree=>relat_last_child
      isfolder = abap_true n_image = '@3Y@' dragdropid = gv_handle )
    ( node_key = 'DISPLAY' relatkey = 'ROOT' relatship = cl_gui_column_tree=>relat_last_child
      isfolder = abap_true n_image = '@3Y@' dragdropid = gv_handle )
    ( node_key = 'P100' relatkey = 'INPUT' relatship = cl_gui_column_tree=>relat_last_child dragdropid = gv_handle )
    ( node_key = 'P200' relatkey = 'DISPLAY' relatship = cl_gui_column_tree=>relat_last_child dragdropid = gv_handle ) ).
  gt_items = VALUE #(
    ( node_key = 'ROOT' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'Product groups' )
    ( node_key = 'ROOT' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = 'Root drop target' )
    ( node_key = 'INPUT' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'Input devices' )
    ( node_key = 'INPUT' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = 'Folder drop target' )
    ( node_key = 'DISPLAY' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'Displays' )
    ( node_key = 'DISPLAY' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = 'Folder drop target' )
    ( node_key = 'P100' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'P100' )
    ( node_key = 'P100' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = 'Mechanical Keyboard' )
    ( node_key = 'P200' item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = 'P200' )
    ( node_key = 'P200' item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = '27 Inch Display' ) ).
ENDFORM.

FORM transfer_tree.
  go_tree->add_nodes_and_items( node_table = gt_nodes
                                item_table = gt_items
    item_table_structure_name              = 'MTREEITM' ).
ENDFORM.

FORM add_grid_item_to_tree USING iv_parent TYPE tv_nodekey iv_id TYPE c iv_name TYPE c.
  DATA lt_nodes TYPE ty_nodes.
  DATA lt_items TYPE ty_items.

  ADD 1 TO gv_sequence.
  gv_added_node = |G{ gv_sequence }|.
  lt_nodes = VALUE #( ( node_key = gv_added_node relatkey = iv_parent
    relatship = cl_gui_column_tree=>relat_last_child dragdropid = gv_handle ) ).
  lt_items = VALUE #(
    ( node_key = gv_added_node item_name = 'NODE' class = cl_gui_column_tree=>item_class_text text = iv_id )
    ( node_key = gv_added_node item_name = 'NAME' class = cl_gui_column_tree=>item_class_text text = iv_name ) ).
  go_tree->add_nodes_and_items( node_table = lt_nodes
                                item_table = lt_items
    item_table_structure_name              = 'MTREEITM' ).
ENDFORM.

FORM undo_last_drop.
  DATA lt_keys TYPE treev_nks.

  TRY.
      CASE gv_last_action.
        WHEN 'GRID'.
          gt_rows = gt_rows_undo.
          go_grid->refresh_table_display(
            is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
          lcl_log=>add( 'Undo restored the grid row order and contents' ).
        WHEN 'TREE'.
          LOOP AT gt_last_nodes INTO DATA(lv_key).
            DATA(lv_parent) = COND tv_nodekey(
              WHEN lv_key = 'P100' OR lv_key = 'P110' THEN 'INPUT' ELSE 'DISPLAY' ).
            go_tree->move_node(
              node_key  = lv_key
              relatkey  = lv_parent
              relatship = cl_gui_column_tree=>relat_last_child ).
          ENDLOOP.
          lcl_log=>add( |Undo restored { lines( gt_last_nodes ) } tree nodes to their initial parents| ).
        WHEN 'ADDNODE'.
          APPEND gv_added_node TO lt_keys.
          go_tree->delete_nodes( lt_keys ).
          lcl_log=>add( |Undo removed transferred tree node { gv_added_node }| ).
        WHEN OTHERS.
          lcl_log=>add( 'Nothing to undo' ).
      ENDCASE.
      CLEAR gv_last_action.
    CATCH cx_root INTO DATA(lx_error).
      lcl_log=>add( |Undo failed: { lx_error->get_text( ) }| ).
  ENDTRY.
ENDFORM.

FORM simulate_payload.
  DATA lo_object TYPE REF TO cl_dragdropobject.
  DATA lo_payload TYPE REF TO lcl_drag_payload.

  CREATE OBJECT lo_object.
  CREATE OBJECT lo_payload EXPORTING iv_source    = 'GRID'
                                     iv_row_index = 1
    iv_id                                         = 'P100'
                                     iv_name      = 'Mechanical Keyboard'.
  lo_object->object = lo_payload.
  lo_object->effect = cl_dragdrop=>copy.
  lcl_log=>add( 'Created a CL_DRAGDROPOBJECT application payload with COPY effect; no UI drop required' ).
  lo_object->abort( ).
  gv_detail = |Payload source { lo_payload->source }, ID { lo_payload->id }; abort state { lo_object->state }|.
ENDFORM.

FORM reset_demo.
  IF go_tree IS BOUND. go_tree->delete_all_nodes( ). ENDIF.
  PERFORM build_data.
  IF go_tree IS BOUND.
    PERFORM transfer_tree.
    go_tree->expand_root_nodes( level_count = 3 ).
  ENDIF.
  IF go_grid IS BOUND.
    go_grid->refresh_table_display(
      is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
  ENDIF.
  CLEAR: gv_last_action, gv_last_node, gv_last_parent, gv_added_node, gt_last_nodes.
  gv_accept_drop = abap_true.
  lcl_log=>add( 'Tree, grid, acceptance mode, and undo snapshot reset' ).
ENDFORM.

FORM show_fallback USING io_error TYPE REF TO cx_root.
  DATA lt_text TYPE ty_text_lines.

  FREE: go_grid, go_tree, go_events, go_dragdrop, go_splitter.
  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( 'Cross-control drag-and-drop is unavailable in this runtime.' )
    ( 'The native report defines flavors/effects/handles, grid reorder, tree reparenting, cross-control payloads, rejection, and undo.' )
    ( 'The pinned open-abap drag/drop and hosted controls currently contain runtime stubs.' ) ).
  go_fallback->set_text_as_r3table( lt_text ).
  go_fallback->set_readonly_mode( 1 ).
  gv_status = 'Cross-control drag/drop unavailable; diagnostic fallback shown'.
  gv_detail = io_error->get_text( ).
ENDFORM.

FORM free_controls.
  FREE: go_events, go_dragdrop.
  IF go_grid IS BOUND. go_grid->free( ). FREE go_grid. ENDIF.
  IF go_tree IS BOUND. go_tree->free( ). FREE go_tree. ENDIF.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_splitter IS BOUND. go_splitter->free( ). FREE go_splitter. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
