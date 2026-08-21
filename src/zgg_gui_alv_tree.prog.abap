REPORT zgg_gui_alv_tree.

TYPES:
  BEGIN OF ty_row,
    id       TYPE c LENGTH 8,
    name     TYPE c LENGTH 30,
    category TYPE c LENGTH 20,
    quantity TYPE i,
    price    TYPE p LENGTH 8 DECIMALS 2,
    currency TYPE c LENGTH 3,
    active   TYPE abap_bool,
  END OF ty_row,
  ty_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

TYPES:
  BEGIN OF ty_node_layout,
    isfolder   TYPE abap_bool,
    expander   TYPE abap_bool,
    n_image    TYPE tv_image,
    exp_image  TYPE tv_image,
    style      TYPE i,
    disabled   TYPE abap_bool,
    dragdropid TYPE i,
  END OF ty_node_layout.

TYPES:
  BEGIN OF ty_item_layout,
    fieldname  TYPE lvc_fname,
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
  END OF ty_item_layout,
  ty_item_layouts TYPE STANDARD TABLE OF ty_item_layout WITH EMPTY KEY,
  ty_text_line TYPE c LENGTH 255,
  ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

CLASS lcl_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_link FOR EVENT link_click OF cl_gui_alv_tree
      IMPORTING fieldname node_key.
    METHODS on_item_double FOR EVENT item_double_click OF cl_gui_alv_tree
      IMPORTING fieldname node_key.
    METHODS on_node_double FOR EVENT node_double_click OF cl_gui_alv_tree
      IMPORTING node_key.
    METHODS on_checkbox FOR EVENT checkbox_change OF cl_gui_alv_tree
      IMPORTING checked fieldname node_key.
    METHODS on_context_selected FOR EVENT node_context_menu_selected OF cl_gui_alv_tree
      IMPORTING fcode node_key.
    METHODS on_drag FOR EVENT on_drag OF cl_gui_alv_tree
      IMPORTING drag_drop_object fieldname node_key.
    METHODS on_drag_multiple FOR EVENT on_drag_multiple OF cl_gui_alv_tree
      IMPORTING drag_drop_object fieldname node_key_table.
ENDCLASS.

DATA gt_outtab TYPE ty_rows.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA gt_leaf_keys TYPE lvc_t_nkey.
DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_tree TYPE REF TO cl_gui_alv_tree.
DATA go_events TYPE REF TO lcl_events.
DATA go_dragdrop TYPE REF TO cl_dragdrop.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_root_key TYPE lvc_nkey.
DATA gv_input_key TYPE lvc_nkey.
DATA gv_display_key TYPE lvc_nkey.
DATA gv_lazy_key TYPE lvc_nkey.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_lazy_loaded TYPE abap_bool.
DATA gv_changed TYPE abap_bool.
DATA gv_native_events_registered TYPE abap_bool.
DATA gv_context_node TYPE lvc_nkey.

INCLUDE zgg_native_alv_tree.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_link.
    gv_status = |LINK_CLICK node { node_key }, field { fieldname }|.
  ENDMETHOD.

  METHOD on_item_double.
    gv_status = |ITEM_DOUBLE_CLICK node { node_key }, field { fieldname }|.
  ENDMETHOD.

  METHOD on_node_double.
    gv_status = |NODE_DOUBLE_CLICK node { node_key }|.
  ENDMETHOD.

  METHOD on_checkbox.
    gv_status = |CHECKBOX_CHANGE node { node_key }, field { fieldname }, checked { checked }|.
  ENDMETHOD.

  METHOD on_context_selected.
    CASE fcode.
      WHEN 'ZDETAIL'.
        PERFORM read_tree_state.
        gv_status = |Context command Show node details selected for { node_key }|.
      WHEN 'ZRESET'.
        PERFORM reset_tree.
        gv_status = |Context command Reset sample selected for { node_key }|.
      WHEN OTHERS.
        gv_status = |NODE_CONTEXT_MENU_SELECTED command { fcode }, node { node_key }|.
    ENDCASE.
  ENDMETHOD.

  METHOD on_drag.
    drag_drop_object->effect = cl_dragdrop=>move.
    gv_status = |ON_DRAG node { node_key }, field { fieldname }|.
  ENDMETHOD.

  METHOD on_drag_multiple.
    drag_drop_object->effect = cl_dragdrop=>move.
    gv_status = |ON_DRAG_MULTIPLE selected nodes { lines( node_key_table ) }, field { fieldname }|.
  ENDMETHOD.
ENDCLASS.

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
    WHEN 'LOAD'.
      PERFORM load_lazy_nodes.
    WHEN 'CHANGE'.
      PERFORM change_nodes_and_items.
    WHEN 'READ'.
      PERFORM read_tree_state.
    WHEN 'EXPAND'.
      PERFORM expand_and_select.
    WHEN 'COLLAPSE'.
      PERFORM collapse_tree.
    WHEN 'DELETE'.
      PERFORM delete_lazy_subtree.
    WHEN 'CALC'.
      PERFORM update_calculations.
    WHEN 'RESET'.
      PERFORM reset_tree.
    WHEN 'TREE_CTX'.
      IMPORT node_key = gv_context_node FROM MEMORY ID 'ZGG_GUI_ALV_TREE_CTX'.
      FREE MEMORY ID 'ZGG_GUI_ALV_TREE_CTX'.
      gv_status = |NODE_CONTEXT_MENU_REQUEST extended for node { gv_context_node }|.
      gv_detail = 'The request menu contains Show node details and Reset sample entries'.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  IF go_tree IS BOUND OR go_fallback IS BOUND.
    RETURN.
  ENDIF.

  PERFORM build_field_catalog.
  TRY.
      CREATE OBJECT go_tree
        EXPORTING parent = go_host
          node_selection_mode = cl_gui_column_tree=>node_sel_mode_multiple
          item_selection = abap_true no_toolbar = abap_false no_html_header = abap_false.
      CREATE OBJECT go_events.
      SET HANDLER go_events->on_link FOR go_tree.
      SET HANDLER go_events->on_item_double FOR go_tree.
      SET HANDLER go_events->on_node_double FOR go_tree.
      SET HANDLER go_events->on_checkbox FOR go_tree.
      SET HANDLER go_events->on_context_selected FOR go_tree.
      SET HANDLER go_events->on_drag FOR go_tree.
      SET HANDLER go_events->on_drag_multiple FOR go_tree.
      PERFORM configure_dragdrop.

      go_tree->set_table_for_first_display(
        EXPORTING is_hierarchy_header = VALUE treev_hhdr(
          heading = 'Product hierarchy' tooltip = 'Folders and product leaf nodes' width = 34 )
          is_exception_field = VALUE lvc_s_l004( excp_fname = 'ACTIVE' excp_led = abap_true )
        CHANGING it_outtab = gt_outtab it_fieldcatalog = gt_fieldcat ).
      PERFORM register_native_context_event.
      go_tree->set_hierarchy_help_fields(
        i_ref_table = 'MARA' i_ref_field = 'MATNR'
        i_doktitle = 'Hierarchy' i_rollname = 'MATNR' ).
      PERFORM add_initial_nodes.
      PERFORM extend_toolbar.
      go_tree->column_optimize( i_include_heading = abap_true ).
      go_tree->frontend_update( ).
      IF gv_native_events_registered = abap_true.
        gv_status = 'ALV tree created with node, item, and context-menu request events'.
      ELSE.
        gv_status = 'ALV tree created; native context-menu request handler unavailable'.
      ENDIF.
      gv_detail = 'Lazy children are loaded only by the Load lazy action; duplicate loads are prevented'.
    CATCH cx_root INTO DATA(lx_error).
      FREE: go_tree, go_events, go_dragdrop.
      PERFORM show_fallback USING lx_error.
  ENDTRY.
ENDFORM.


FORM build_field_catalog.
  gt_fieldcat = VALUE #(
    ( fieldname = 'ID' col_pos = 1 coltext = 'Product ID' key = abap_true outputlen = 10 )
    ( fieldname = 'NAME' col_pos = 2 coltext = 'Name' outputlen = 28 )
    ( fieldname = 'CATEGORY' col_pos = 3 coltext = 'Category' outputlen = 18 )
    ( fieldname = 'QUANTITY' col_pos = 4 coltext = 'Quantity' do_sum = abap_true outputlen = 10 )
    ( fieldname = 'PRICE' col_pos = 5 coltext = 'Price' cfieldname = 'CURRENCY'
      do_sum = abap_true decimals_o = 2 outputlen = 14 )
    ( fieldname = 'CURRENCY' col_pos = 6 coltext = 'Currency' outputlen = 8 )
    ( fieldname = 'ACTIVE' col_pos = 7 coltext = 'Active' checkbox = abap_true outputlen = 7 ) ).
ENDFORM.

FORM configure_dragdrop.
  CREATE OBJECT go_dragdrop.
  go_dragdrop->add(
    flavor = 'GG_TREE_ROWS' dragsrc = abap_true droptarget = abap_true
    effect = cl_dragdrop=>move effect_in_ctrl = cl_dragdrop=>move ).
  go_tree->set_default_drop( i_drag_drop = go_dragdrop ).
ENDFORM.

FORM add_initial_nodes.
  DATA ls_folder TYPE ty_node_layout.
  DATA lt_item_layout TYPE ty_item_layouts.

  CLEAR: gt_outtab, gt_leaf_keys.
  ls_folder = VALUE #( isfolder = abap_true expander = abap_true
    n_image = '@3Y@' exp_image = '@3W@' ).
  go_tree->add_node(
    EXPORTING i_relat_node_key = space
      i_relationship = cl_gui_column_tree=>relat_last_child
      is_node_layout = ls_folder i_node_text = 'Product catalog'
    IMPORTING e_new_node_key = gv_root_key ).
  go_tree->add_node(
    EXPORTING i_relat_node_key = gv_root_key
      i_relationship = cl_gui_column_tree=>relat_last_child
      is_node_layout = ls_folder i_node_text = 'Input devices'
    IMPORTING e_new_node_key = gv_input_key ).
  go_tree->add_node(
    EXPORTING i_relat_node_key = gv_root_key
      i_relationship = cl_gui_column_tree=>relat_last_child
      is_node_layout = ls_folder i_node_text = 'Displays'
    IMPORTING e_new_node_key = gv_display_key ).
  go_tree->add_node(
    EXPORTING i_relat_node_key = gv_root_key
      i_relationship = cl_gui_column_tree=>relat_last_child
      is_node_layout = ls_folder i_node_text = 'Lazy-loaded products'
    IMPORTING e_new_node_key = gv_lazy_key ).

  lt_item_layout = VALUE #(
    ( fieldname = 'NAME' class = cl_gui_column_tree=>item_class_link style = 1 )
    ( fieldname = 'ACTIVE' class = cl_gui_column_tree=>item_class_checkbox editable = abap_true ) ).
  PERFORM add_leaf USING gv_input_key 'P100' 'Mechanical Keyboard' 'Input' 12 '129.90' 'EUR' abap_true lt_item_layout.
  PERFORM add_leaf USING gv_input_key 'P110' 'Ergonomic Mouse' 'Input' 7 '74.50' 'EUR' abap_true lt_item_layout.
  PERFORM add_leaf USING gv_display_key 'P200' '27 Inch Display' 'Display' 4 '389.00' 'EUR' abap_true lt_item_layout.
  go_tree->expand_node( i_node_key = gv_root_key i_level_count = 2 ).
  go_tree->set_top_node( i_node_key = gv_root_key ).
ENDFORM.

FORM add_leaf USING iv_parent TYPE lvc_nkey iv_id TYPE c iv_name TYPE c
    iv_category TYPE c iv_quantity TYPE i iv_price TYPE p iv_currency TYPE c
    iv_active TYPE abap_bool it_item_layout TYPE ty_item_layouts.
  DATA ls_row TYPE ty_row.
  DATA lv_key TYPE lvc_nkey.

  ls_row = VALUE #(
    id = iv_id name = iv_name category = iv_category quantity = iv_quantity
    price = iv_price currency = iv_currency active = iv_active ).
  APPEND ls_row TO gt_outtab.
  go_tree->add_node(
    EXPORTING i_relat_node_key = iv_parent
      i_relationship = cl_gui_column_tree=>relat_last_child
      is_outtab_line = ls_row it_item_layout = it_item_layout i_node_text = iv_name
    IMPORTING e_new_node_key = lv_key ).
  APPEND lv_key TO gt_leaf_keys.
ENDFORM.

FORM extend_toolbar.
  DATA lo_toolbar TYPE REF TO cl_gui_toolbar.

  go_tree->get_toolbar_object( IMPORTING er_toolbar = lo_toolbar ).
  IF lo_toolbar IS BOUND.
    lo_toolbar->add_button(
      fcode = 'ZLOAD' icon = '@17@' butn_type = 0
      text = 'Load lazy' quickinfo = 'Load lazy-folder children' ).
    lo_toolbar->add_button(
      fcode = 'ZCALC' icon = '@15@' butn_type = 0
      text = 'Calculate' quickinfo = 'Update calculated columns' ).
  ENDIF.
ENDFORM.

FORM load_lazy_nodes.
  DATA lt_item_layout TYPE ty_item_layouts.

  IF go_tree IS NOT BOUND.
    RETURN.
  ENDIF.
  IF gv_lazy_loaded = abap_true.
    gv_status = 'Lazy children already loaded; duplicate insertion prevented'.
    RETURN.
  ENDIF.
  lt_item_layout = VALUE #(
    ( fieldname = 'NAME' class = cl_gui_column_tree=>item_class_link )
    ( fieldname = 'ACTIVE' class = cl_gui_column_tree=>item_class_checkbox editable = abap_true ) ).
  PERFORM add_leaf USING gv_lazy_key 'P300' 'USB-C Dock' 'Connectivity' 0 '219.00' 'EUR' abap_false lt_item_layout.
  PERFORM add_leaf USING gv_lazy_key 'P400' 'Conference Speaker' 'Audio' 9 '159.00' 'EUR' abap_true lt_item_layout.
  gv_lazy_loaded = abap_true.
  go_tree->expand_node( i_node_key = gv_lazy_key i_level_count = 1 ).
  go_tree->frontend_update( ).
  gv_status = 'Two product leaves loaded under the lazy folder and expanded'.
ENDFORM.

FORM change_nodes_and_items.
  DATA ls_row TYPE ty_row.
  DATA lt_item_layout TYPE ty_item_layouts.

  IF gt_leaf_keys IS INITIAL.
    RETURN.
  ENDIF.
  READ TABLE gt_leaf_keys INDEX 1 INTO DATA(lv_key).
  go_tree->get_outtab_line( EXPORTING i_node_key = lv_key IMPORTING e_outtab_line = ls_row ).
  gv_changed = xsdbool( gv_changed = abap_false ).
  ls_row-name = COND #( WHEN gv_changed = abap_true THEN 'Keyboard - changed node' ELSE 'Mechanical Keyboard' ).
  ls_row-quantity = COND #( WHEN gv_changed = abap_true THEN 15 ELSE 12 ).
  lt_item_layout = VALUE #(
    ( fieldname = 'NAME' class = cl_gui_column_tree=>item_class_link chosen = gv_changed ) ).
  go_tree->change_node(
    i_node_key = lv_key i_outtab_line = ls_row it_item_layout = lt_item_layout ).
  go_tree->change_item(
    i_node_key = lv_key i_fieldname = 'NAME' i_data = ls_row-name
    is_item_layout = VALUE ty_item_layout( fieldname = 'NAME'
      class = cl_gui_column_tree=>item_class_link chosen = gv_changed ) ).
  go_tree->frontend_update( ).
  gv_status = |Node output row and NAME item changed in place; alternate state { gv_changed }|.
ENDFORM.

FORM read_tree_state.
  DATA lt_selected TYPE lvc_t_nkey.
  DATA lt_expanded TYPE lvc_t_nkey.
  DATA lt_children TYPE lvc_t_nkey.
  DATA lt_subtree TYPE lvc_t_nkey.
  DATA lt_checked TYPE lvc_t_chit.
  DATA lv_parent TYPE lvc_nkey.
  DATA lv_top TYPE lvc_nkey.
  DATA lv_selected_node TYPE lvc_nkey.
  DATA lv_selected_field TYPE lvc_fname.
  DATA ls_row TYPE ty_row.

  IF go_tree IS NOT BOUND.
    RETURN.
  ENDIF.
  go_tree->get_selected_nodes( CHANGING ct_selected_nodes = lt_selected ).
  go_tree->get_selected_item(
    IMPORTING e_fieldname = lv_selected_field e_selected_node = lv_selected_node ).
  go_tree->get_expanded_nodes( CHANGING ct_expanded_nodes = lt_expanded ).
  go_tree->get_checked_items( IMPORTING et_checked_items = lt_checked ).
  go_tree->get_children( EXPORTING i_node_key = gv_root_key IMPORTING et_children = lt_children ).
  go_tree->get_subtree( EXPORTING i_node_key = gv_root_key IMPORTING et_subtree_nodes = lt_subtree ).
  go_tree->get_parent( EXPORTING i_node_key = gv_input_key IMPORTING e_parent_node_key = lv_parent ).
  go_tree->get_top_node( IMPORTING e_node_key = lv_top ).
  IF gt_leaf_keys IS NOT INITIAL.
    go_tree->get_outtab_line( EXPORTING i_node_key = gt_leaf_keys[ 1 ] IMPORTING e_outtab_line = ls_row ).
  ENDIF.
  gv_status = |Selected { lines( lt_selected ) }; expanded { lines( lt_expanded ) }; checked { lines( lt_checked ) }; children { lines( lt_children ) }|.
  gv_detail = |Subtree { lines( lt_subtree ) }; parent { lv_parent }; top { lv_top }; selected item { lv_selected_node }/{ lv_selected_field }|.
ENDFORM.

FORM expand_and_select.
  DATA lt_select TYPE lvc_t_nkey.

  lt_select = VALUE #( ( gv_input_key ) ( gv_display_key ) ).
  go_tree->expand_nodes( it_node_key = lt_select ).
  go_tree->set_selected_nodes( it_selected_nodes = lt_select ).
  go_tree->set_top_node( i_node_key = gv_root_key ).
  go_tree->frontend_update( ).
  gv_status = 'Input and Display folders expanded and selected; root retained as top node'.
ENDFORM.

FORM collapse_tree.
  go_tree->collapse_subtree( i_node_key = gv_root_key ).
  go_tree->unselect_nodes( it_node_key = VALUE lvc_t_nkey( ( gv_input_key ) ( gv_display_key ) ) ).
  go_tree->set_top_node( i_node_key = gv_root_key ).
  go_tree->frontend_update( ).
  gv_status = 'Root subtree collapsed, folder selections cleared, and top node retained'.
ENDFORM.

FORM delete_lazy_subtree.
  IF gv_lazy_loaded = abap_false.
    gv_status = 'Load lazy children before deleting their subtree'.
    RETURN.
  ENDIF.
  TRY.
      CALL METHOD go_tree->('DELETE_SUBTREE') EXPORTING i_node_key = gv_lazy_key.
      DELETE gt_leaf_keys WHERE table_line = gv_lazy_key.
      CLEAR gv_lazy_loaded.
      go_tree->frontend_update( ).
      gv_status = 'Lazy subtree deleted through the native ALV tree API'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |DELETE_SUBTREE unavailable: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM update_calculations.
  go_tree->update_calculations( no_frontend_update = abap_false ).
  go_tree->column_optimize( i_include_heading = abap_true ).
  go_tree->frontend_update( ).
  gv_status = 'Calculated quantity and price columns updated and all columns optimized with headings'.
ENDFORM.

FORM reset_tree.
  IF go_tree IS NOT BOUND.
    RETURN.
  ENDIF.
  go_tree->delete_all_nodes( ).
  CLEAR: gv_lazy_loaded, gv_changed.
  PERFORM add_initial_nodes.
  go_tree->update_calculations( ).
  go_tree->column_optimize( i_include_heading = abap_true ).
  go_tree->frontend_update( ).
  gv_status = 'Nodes, items, selections, expansion, top node, lazy state, and calculated values reset'.
ENDFORM.

FORM show_fallback USING io_error TYPE REF TO cx_root.
  DATA lt_text TYPE ty_text_lines.

  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( 'CL_GUI_ALV_TREE is unavailable or nonfunctional in this runtime.' )
    ( 'The native SAP report retains hierarchy, data columns, events, mutations, and state round trips.' )
    ( 'The pinned open-abap tree constructor currently terminates with an assertion.' ) ).
  go_fallback->set_text_as_r3table( table = lt_text ).
  go_fallback->set_readonly_mode( readonly_mode = 1 ).
  gv_status = 'ALV tree unavailable; a non-terminating text fallback is displayed'.
  gv_detail = io_error->get_text( ).
ENDFORM.

FORM free_controls.
  PERFORM unregister_context_event.
  FREE: go_events, go_dragdrop.
  IF go_tree IS BOUND. go_tree->free( ). FREE go_tree. ENDIF.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
