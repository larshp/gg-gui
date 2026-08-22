REPORT zgg_gui_alv_grid.

TYPES ty_rows TYPE zcl_gg_gui_demo_data=>ty_products.
TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

DATA gt_rows TYPE ty_rows.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA gt_sort TYPE lvc_t_sort.
DATA gt_filter TYPE lvc_t_filt.
DATA gs_layout TYPE lvc_s_layo.
DATA gs_print TYPE lvc_s_prnt.
DATA gs_variant TYPE disvariant.
DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_refresh_count TYPE i.
DATA gv_input_ready TYPE abap_bool.
DATA gv_alternate_layout TYPE abap_bool.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_controls.
ENDMODULE.

MODULE dispatch_0100 INPUT.
  DATA lv_return_code TYPE i.

  IF go_grid IS BOUND.
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
    WHEN 'SELECT'.
      PERFORM selection_roundtrip.
    WHEN 'FRONTEND'.
      PERFORM frontend_roundtrip.
    WHEN 'SCROLL'.
      PERFORM scroll_roundtrip.
    WHEN 'STATE'.
      PERFORM read_grid_state.
    WHEN 'CRITERIA'.
      PERFORM criteria_roundtrip.
    WHEN 'VARIANT'.
      PERFORM variant_roundtrip.
    WHEN 'REFRESH'.
      PERFORM refresh_grid.
    WHEN 'EXPORT'.
      PERFORM request_export.
    WHEN 'DDIC'.
      PERFORM build_ddic_catalog.
    WHEN 'PRESENT'.
      PERFORM toggle_presentation.
    WHEN 'RESET'.
      PERFORM reset_grid.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  IF go_grid IS BOUND OR go_fallback IS BOUND.
    RETURN.
  ENDIF.

  PERFORM build_rows.
  PERFORM build_manual_catalog.
  PERFORM build_configuration.
  TRY.
      CREATE OBJECT go_grid EXPORTING i_parent      = go_host
                                      i_appl_events = abap_true.
      go_grid->set_table_for_first_display(
        EXPORTING is_variant = gs_variant
                  i_save = 'A'
                  i_default = abap_true
          is_layout = gs_layout
                  is_print = gs_print
          it_toolbar_excluding = VALUE ui_functions(
            ( cl_gui_alv_grid=>mc_fc_graph )
            ( cl_gui_alv_grid=>mc_fc_word_processor ) )
        CHANGING it_outtab = gt_rows it_fieldcatalog = gt_fieldcat
          it_sort = gt_sort it_filter = gt_filter ).
      go_grid->set_gridtitle( 'Basic ALV Grid Control - deterministic products' ).
      go_grid->set_3d_border( 1 ).
      gv_status = 'ALV Grid created with a manual catalog, layout, exclusions, sort, filter, totals, print, and variant key'.
      gv_detail = 'The standard toolbar provides sort, filter, subtotal, aggregate, print, layout, and export commands'.
    CATCH cx_root INTO DATA(lx_error).
      FREE go_grid.
      PERFORM show_fallback USING lx_error.
  ENDTRY.
ENDFORM.

FORM build_rows.
  gt_rows = zcl_gg_gui_demo_data=>products( ).
ENDFORM.

FORM build_manual_catalog.
  CLEAR gt_fieldcat.
  gt_fieldcat = VALUE #(
    ( fieldname = 'ID' col_pos = 1 coltext = 'Product ID' key = abap_true
      hotspot = abap_true outputlen = 10 inttype = 'C' intlen = 8 )
    ( fieldname = 'NAME' col_pos = 2 coltext = 'Product name'
      outputlen = 28 inttype = 'C' intlen = 30 )
    ( fieldname = 'CATEGORY' col_pos = 3 coltext = 'Category'
      outputlen = 18 inttype = 'C' intlen = 20 )
    ( fieldname = 'QUANTITY' col_pos = 4 coltext = 'Quantity' do_sum = abap_true
      outputlen = 10 inttype = 'I' intlen = 4 )
    ( fieldname = 'PRICE' col_pos = 5 coltext = 'Unit price' do_sum = abap_true
      cfieldname = 'CURRENCY' outputlen = 14 inttype = 'P' intlen = 8 decimals_o = 2 )
    ( fieldname = 'CURRENCY' col_pos = 6 coltext = 'Currency'
      outputlen = 8 inttype = 'C' intlen = 3 )
    ( fieldname = 'ACTIVE' col_pos = 7 coltext = 'Active' checkbox = abap_true
      outputlen = 7 inttype = 'C' intlen = 1 )
    ( fieldname = 'STATUS' col_pos = 8 coltext = 'Status'
      outputlen = 7 inttype = 'C' intlen = 1 )
    ( fieldname = 'DESCRIPTION' col_pos = 9 coltext = 'Description'
      outputlen = 36 inttype = 'g' ) ).
ENDFORM.

FORM build_configuration.
  CLEAR: gs_layout, gs_print, gs_variant, gt_sort, gt_filter.
  gs_layout-zebra = abap_true.
  gs_layout-cwidth_opt = abap_true.
  gs_layout-sel_mode = 'A'.
  gs_layout-smalltitle = abap_true.
  gs_layout-grid_title = 'Basic ALV Grid Control'.

  gs_print-print = abap_true.
  gs_print-prnt_title = abap_true.
  gs_print-footline = abap_true.
  gs_print-prnt_info = abap_true.

  gs_variant-report = sy-repid.
  gs_variant-handle = 'BSC1'.
  gs_variant-username = sy-uname.

  gt_sort = VALUE #(
    ( spos = 1 fieldname = 'CATEGORY' up = abap_true subtot = abap_true )
    ( spos = 2 fieldname = 'NAME' up = abap_true ) ).
  gt_filter = VALUE #(
    ( fieldname = 'ACTIVE' sign = 'I' option = 'EQ' low = abap_true ) ).
ENDFORM.

FORM selection_roundtrip.
  DATA lt_rows TYPE lvc_t_row.
  DATA lt_row_numbers TYPE lvc_t_roid.
  DATA lt_columns TYPE lvc_t_col.
  DATA lt_cells TYPE lvc_t_cell.
  DATA ls_row TYPE lvc_s_row.
  DATA ls_row_number TYPE lvc_s_roid.
  DATA ls_column TYPE lvc_s_col.
  DATA lv_row TYPE i.
  DATA lv_column TYPE i.
  DATA lv_value TYPE c LENGTH 128.

  IF go_grid IS NOT BOUND.
    gv_status = 'ALV Grid is unavailable; selection state cannot be inspected'.
    RETURN.
  ENDIF.
  TRY.
      go_grid->get_selected_rows(
        IMPORTING et_index_rows = lt_rows et_row_no = lt_row_numbers ).
      go_grid->get_selected_columns( IMPORTING et_index_columns = lt_columns ).
      go_grid->get_selected_cells( IMPORTING et_cell = lt_cells ).
      go_grid->get_current_cell(
        IMPORTING e_row = lv_row e_value = lv_value e_col = lv_column
          es_row_id = ls_row es_col_id = ls_column es_row_no = ls_row_number ).

      lt_rows = VALUE #( ( index = 1 ) ( index = 3 ) ).
      lt_columns = VALUE #( ( fieldname = 'ID' ) ( fieldname = 'PRICE' ) ).
      lt_cells = VALUE #(
        ( row_id-index = 1 col_id-fieldname = 'ID' )
        ( row_id-index = 3 col_id-fieldname = 'PRICE' ) ).
      go_grid->set_selected_rows( it_index_rows = lt_rows ).
      go_grid->set_selected_columns( lt_columns ).
      go_grid->set_selected_cells( lt_cells ).
      go_grid->set_current_cell_via_id(
        is_row_id    = VALUE #( index = 1 )
        is_column_id = VALUE #( fieldname = 'NAME' ) ).
      gv_status = |Read rows { lines( lt_row_numbers ) }, columns { lines( lt_columns ) }, cells { lines( lt_cells ) }; then selected examples|.
      gv_detail = |Previous current cell: row { lv_row }, column { ls_column-fieldname }, value { lv_value }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Selection round trip failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM frontend_roundtrip.
  DATA lt_frontend_catalog TYPE lvc_t_fcat.
  DATA ls_frontend_layout TYPE lvc_s_layo.

  IF go_grid IS NOT BOUND.
    gv_status = 'ALV Grid is unavailable; frontend metadata cannot be inspected'.
    RETURN.
  ENDIF.
  TRY.
      go_grid->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = lt_frontend_catalog ).
      go_grid->get_frontend_layout( IMPORTING es_layout = ls_frontend_layout ).
      gv_alternate_layout = xsdbool( gv_alternate_layout = abap_false ).
      READ TABLE lt_frontend_catalog ASSIGNING FIELD-SYMBOL(<field>) WITH KEY fieldname = 'NAME'.
      IF sy-subrc = 0.
        <field>-outputlen = COND #( WHEN gv_alternate_layout = abap_true THEN 20 ELSE 28 ).
        <field>-emphasize = COND #( WHEN gv_alternate_layout = abap_true THEN 'C510' ELSE space ).
      ENDIF.
      ls_frontend_layout-zebra = xsdbool( gv_alternate_layout = abap_false ).
      ls_frontend_layout-grid_title = COND #(
        WHEN gv_alternate_layout = abap_true THEN 'Frontend catalog and layout replaced'
        ELSE 'Basic ALV Grid Control' ).
      go_grid->set_frontend_fieldcatalog( lt_frontend_catalog ).
      go_grid->set_frontend_layout( ls_frontend_layout ).
      gv_status = |Read and replaced { lines( lt_frontend_catalog ) } frontend catalog entries and the current frontend layout|.
      gv_detail = |Alternate frontend presentation active: { gv_alternate_layout }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Frontend metadata round trip failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM scroll_roundtrip.
  DATA ls_row_number TYPE lvc_s_roid.
  DATA ls_row TYPE lvc_s_row.
  DATA ls_column TYPE lvc_s_col.

  IF go_grid IS NOT BOUND.
    gv_status = 'ALV Grid is unavailable; scroll state cannot be inspected'.
    RETURN.
  ENDIF.
  TRY.
      go_grid->get_scroll_info_via_id(
        IMPORTING es_row_no = ls_row_number es_row_info = ls_row es_col_info = ls_column ).
      go_grid->set_scroll_info_via_id(
        is_row_info = ls_row
        is_col_info = ls_column
        is_row_no   = ls_row_number ).
      gv_status = |Scroll position read and restored: row { ls_row-index }, column { ls_column-fieldname }|.
      gv_detail = 'The control keeps its top row and left column across refresh-oriented operations'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Scroll round trip failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM read_grid_state.
  DATA lt_filtered TYPE lvc_t_fidx.
  DATA lt_groups TYPE lvc_t_grpl.
  DATA lt_current_sort TYPE lvc_t_sort.
  DATA lt_current_filter TYPE lvc_t_filt.
  DATA ls_current_print TYPE lvc_s_prnt.
  DATA lr_subtotals TYPE REF TO data.

  IF go_grid IS NOT BOUND.
    gv_status = 'ALV Grid is unavailable; calculated state cannot be inspected'.
    RETURN.
  ENDIF.
  TRY.
      go_grid->get_filtered_entries( IMPORTING et_filtered_entries = lt_filtered ).
      go_grid->get_subtotals(
        IMPORTING ep_collect00 = lr_subtotals et_grouplevels = lt_groups ).
      go_grid->get_frontend_print( IMPORTING es_print = ls_current_print ).
      go_grid->get_sort_criteria( IMPORTING et_sort = lt_current_sort ).
      go_grid->get_filter_criteria( IMPORTING et_filter = lt_current_filter ).
      gv_status = |Filtered { lines( lt_filtered ) }; groups { lines( lt_groups ) }; sorts { lines( lt_current_sort ) }; filters { lines( lt_current_filter ) }|.
      gv_detail = |Subtotal data bound: { xsdbool( lr_subtotals IS BOUND ) }; print title enabled: { ls_current_print-prnt_title }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Grid state read failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM criteria_roundtrip.
  DATA lt_current_sort TYPE lvc_t_sort.
  DATA lt_current_filter TYPE lvc_t_filt.

  IF go_grid IS NOT BOUND.
    gv_status = 'ALV Grid is unavailable; criteria cannot be changed'.
    RETURN.
  ENDIF.
  TRY.
      go_grid->get_sort_criteria( IMPORTING et_sort = lt_current_sort ).
      go_grid->get_filter_criteria( IMPORTING et_filter = lt_current_filter ).
      IF lt_current_filter IS INITIAL.
        lt_current_filter = gt_filter.
      ELSE.
        CLEAR lt_current_filter.
      ENDIF.
      go_grid->set_sort_criteria( gt_sort ).
      go_grid->set_filter_criteria( lt_current_filter ).
      go_grid->refresh_table_display(
        is_stable      = VALUE lvc_s_stbl( row = abap_true col = abap_true )
        i_soft_refresh = abap_false ).
      gv_status = |Sort, subtotal, and aggregate criteria restored; filter count is now { lines( lt_current_filter ) }|.
      gv_detail = 'Quantity and price total fields remain active while category supplies subtotal groups'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Criteria round trip failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM variant_roundtrip.
  DATA ls_current TYPE disvariant.
  DATA lv_save TYPE char1.
  DATA lv_exit TYPE abap_bool.

  IF go_grid IS NOT BOUND.
    gv_status = 'ALV Grid is unavailable; variants cannot be saved or loaded'.
    RETURN.
  ENDIF.
  TRY.
      go_grid->get_variant( IMPORTING es_variant = ls_current e_save = lv_save ).
      go_grid->save_variant( EXPORTING i_dialog = abap_true IMPORTING e_exit = lv_exit ).
      IF lv_exit = abap_false AND ls_current-variant IS NOT INITIAL.
        go_grid->set_variant( is_variant = ls_current
                              i_save     = lv_save ).
      ENDIF.
      gv_status = |Variant dialog exit flag { lv_exit }; current variant { ls_current-variant }|.
      gv_detail = 'Only the current report and BSC1 handle are used by this sample'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Variant save/load failed or was canceled: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM refresh_grid.
  IF go_grid IS NOT BOUND.
    gv_status = 'ALV Grid is unavailable; no output can be refreshed'.
    RETURN.
  ENDIF.
  ADD 1 TO gv_refresh_count.
  READ TABLE gt_rows INDEX 1 ASSIGNING FIELD-SYMBOL(<row>).
  IF sy-subrc = 0.
    <row>-quantity = 12 + gv_refresh_count.
  ENDIF.
  TRY.
      go_grid->refresh_table_display(
        is_stable      = VALUE lvc_s_stbl( row = abap_true col = abap_true )
        i_soft_refresh = abap_true ).
      gv_status = |Stable soft refresh complete; P100 quantity is { <row>-quantity }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Grid refresh failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM request_export.
  IF go_grid IS NOT BOUND.
    gv_status = 'ALV Grid is unavailable; export cannot be requested'.
    RETURN.
  ENDIF.
  TRY.
      go_grid->set_user_command( '&XXL' ).
      gv_status = 'The standard spreadsheet export command was sent to the ALV Grid'.
      gv_detail = 'Frontend security and installed spreadsheet integration determine the resulting dialog'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Standard ALV export failed or was canceled: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM build_ddic_catalog.
  DATA lt_ddic_catalog TYPE lvc_t_fcat.

  TRY.
      CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
        EXPORTING i_structure_name = 'LVC_S_LAYO'
        CHANGING ct_fieldcat = lt_ddic_catalog
        EXCEPTIONS inconsistent_interface = 1 program_error = 2 OTHERS = 3.
      IF sy-subrc = 0.
        gv_status = |DDIC metadata generated { lines( lt_ddic_catalog ) } fields for standard structure LVC_S_LAYO|.
        gv_detail = |Manual output catalog contains { lines( gt_fieldcat ) } fields; DDIC and manual construction are intentionally compared|.
      ELSE.
        gv_status = |LVC_FIELDCATALOG_MERGE returned subrc { sy-subrc }|.
      ENDIF.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |DDIC field catalog generation failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM toggle_presentation.
  DATA lv_ready TYPE i.

  IF go_grid IS NOT BOUND.
    gv_status = 'ALV Grid is unavailable; presentation state cannot be changed'.
    RETURN.
  ENDIF.
  gv_input_ready = xsdbool( gv_input_ready = abap_false ).
  TRY.
      go_grid->set_gridtitle( COND #(
        WHEN gv_input_ready = abap_true THEN 'Ready-for-input state enabled'
        ELSE 'Read-only Basic ALV Grid Control' ) ).
      go_grid->set_ready_for_input( COND #( WHEN gv_input_ready = abap_true THEN 1 ELSE 0 ) ).
      go_grid->set_3d_border( COND #( WHEN gv_input_ready = abap_true THEN 0 ELSE 1 ) ).
      lv_ready = go_grid->is_ready_for_input( ).
      gv_status = |Grid title, ready-for-input state, and 3D border changed; reported input state { lv_ready }|.
      gv_detail = 'This basic report changes control state but leaves editable-cell behavior to ZGG_GUI_ALV_EDIT'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Presentation change failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM reset_grid.
  CLEAR: gv_refresh_count, gv_input_ready, gv_alternate_layout.
  PERFORM build_rows.
  PERFORM build_manual_catalog.
  PERFORM build_configuration.
  IF go_grid IS BOUND.
    TRY.
        go_grid->set_frontend_fieldcatalog( gt_fieldcat ).
        go_grid->set_frontend_layout( gs_layout ).
        go_grid->set_sort_criteria( gt_sort ).
        go_grid->set_filter_criteria( gt_filter ).
        go_grid->set_variant( is_variant = gs_variant
                              i_save     = 'A' ).
        go_grid->set_gridtitle( 'Basic ALV Grid Control - deterministic products' ).
        go_grid->set_ready_for_input( 0 ).
        go_grid->set_3d_border( 1 ).
        go_grid->refresh_table_display(
          is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
        gv_status = 'Rows, catalog, layout, sort, filter, variant key, title, input state, and border reset'.
      CATCH cx_root INTO DATA(lx_error).
        gv_status = |Grid reset failed: { lx_error->get_text( ) }|.
    ENDTRY.
  ELSE.
    gv_status = 'Deterministic grid state reset; the runtime fallback remains visible'.
  ENDIF.
ENDFORM.

FORM show_fallback USING io_error TYPE REF TO cx_root.
  DATA lt_text TYPE ty_text_lines.

  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( 'CL_GUI_ALV_GRID is unavailable or nonfunctional in this runtime.' )
    ( 'The native SAP report remains syntax checked and guards grid construction.' )
    ( 'The pinned open-abap-gui grid constructor currently terminates with an assertion.' ) ).
  go_fallback->set_text_as_r3table( lt_text ).
  go_fallback->set_readonly_mode( 1 ).
  gv_status = 'ALV Grid unavailable; a non-terminating text fallback is displayed'.
  gv_detail = io_error->get_text( ).
ENDFORM.

FORM free_controls.
  IF go_grid IS BOUND. go_grid->free( ). FREE go_grid. ENDIF.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
