REPORT zgg_gui_salv_table.

TYPES:
  BEGIN OF ty_int4_column,
    columnname TYPE lvc_fname,
    value      TYPE i,
  END OF ty_int4_column,
  ty_int4_columns TYPE STANDARD TABLE OF ty_int4_column WITH EMPTY KEY.

TYPES:
  BEGIN OF ty_row,
    id            TYPE c LENGTH 8,
    name          TYPE c LENGTH 30,
    category      TYPE c LENGTH 20,
    quantity      TYPE i,
    unit          TYPE c LENGTH 3,
    price         TYPE p LENGTH 8 DECIMALS 2,
    currency      TYPE c LENGTH 3,
    active        TYPE abap_bool,
    status        TYPE c LENGTH 1,
    description   TYPE string,
    exception     TYPE i,
    technical     TYPE c LENGTH 12,
    cell_colors   TYPE lvc_t_scol,
    cell_types    TYPE ty_int4_columns,
    link_handles  TYPE ty_int4_columns,
  END OF ty_row,
  ty_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY,
  ty_text_line TYPE c LENGTH 255,
  ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

TYPES:
  BEGIN OF ty_layout_key,
    report TYPE syrepid,
    handle TYPE c LENGTH 4,
  END OF ty_layout_key.

CLASS lcl_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_added_function FOR EVENT added_function OF cl_salv_events_table
      IMPORTING e_salv_function.
    METHODS on_double_click FOR EVENT double_click OF cl_salv_events_table
      IMPORTING row column.
    METHODS on_link_click FOR EVENT link_click OF cl_salv_events_table
      IMPORTING row column.
ENDCLASS.

DATA gt_rows TYPE ty_rows.
DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_salv TYPE REF TO cl_salv_table.
DATA go_events TYPE REF TO lcl_events.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_refresh_count TYPE i.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_added_function.
    gv_status = |Custom SALV function { e_salv_function } selected|.
    CASE e_salv_function.
      WHEN 'ZRESET'.
        PERFORM reset_data.
      WHEN 'ZSELECT'.
        PERFORM read_selection.
    ENDCASE.
  ENDMETHOD.

  METHOD on_double_click.
    gv_status = |Double-click: row { row }, column { column }|.
    READ TABLE gt_rows INDEX row INTO DATA(ls_row).
    IF sy-subrc = 0.
      gv_detail = |{ ls_row-id }: { ls_row-description }|.
    ENDIF.
  ENDMETHOD.

  METHOD on_link_click.
    gv_status = |Link-click: row { row }, column { column }|.
    READ TABLE gt_rows INDEX row INTO DATA(ls_row).
    IF sy-subrc = 0.
      gv_detail = |Hyperlink handle for { ls_row-id } was activated|.
    ENDIF.
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

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.

  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_ok_code.
    WHEN 'SELECT'.
      PERFORM read_selection.
    WHEN 'LAYOUT'.
      PERFORM inspect_layouts.
    WHEN 'EXPORT'.
      PERFORM export_xml.
    WHEN 'REFRESH'.
      PERFORM refresh_data.
    WHEN 'POPUP'.
      PERFORM show_popup.
    WHEN 'FULL'.
      PERFORM show_fullscreen.
    WHEN 'OFFLINE'.
      PERFORM inspect_offline.
    WHEN 'RESET'.
      PERFORM reset_data.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  IF go_salv IS BOUND OR go_fallback IS BOUND.
    RETURN.
  ENDIF.

  PERFORM build_rows.
  TRY.
      cl_salv_table=>factory(
        EXPORTING r_container = go_host container_name = 'CC_MAIN'
        IMPORTING r_salv_table = go_salv
        CHANGING t_table = gt_rows ).
      PERFORM configure_salv USING go_salv.
      CREATE OBJECT go_events.
      DATA(lo_event_source) = go_salv->get_event( ).
      SET HANDLER go_events->on_added_function FOR lo_event_source.
      SET HANDLER go_events->on_double_click FOR lo_event_source.
      SET HANDLER go_events->on_link_click FOR lo_event_source.
      go_salv->display( ).
      gv_status = 'Container SALV created with generated columns, functions, formatting, events, and five demo rows'.
      gv_detail = 'Use the buttons to inspect selection/layout/export plus popup, fullscreen, and offline modes'.
    CATCH cx_root INTO DATA(lx_error).
      FREE: go_salv, go_events.
      PERFORM show_fallback USING lx_error.
  ENDTRY.
ENDFORM.

FORM build_rows.
  DATA lt_products TYPE zcl_gg_gui_demo_data=>ty_products.
  DATA ls_color TYPE lvc_s_scol.

  CLEAR gt_rows.
  lt_products = zcl_gg_gui_demo_data=>products( ).
  LOOP AT lt_products INTO DATA(ls_product).
    DATA(ls_row) = VALUE ty_row(
      id = ls_product-id name = ls_product-name category = ls_product-category
      quantity = ls_product-quantity unit = 'EA' price = ls_product-price
      currency = ls_product-currency active = ls_product-active status = ls_product-status
      description = ls_product-description exception = COND #(
        WHEN ls_product-quantity = 0 THEN 1
        WHEN ls_product-quantity < 5 THEN 2 ELSE 3 )
      technical = |ROW{ sy-tabix }| ).

    ls_color-fname = 'CATEGORY'.
    ls_color-color-col = COND #(
      WHEN ls_product-category = 'Input' THEN 5
      WHEN ls_product-category = 'Display' THEN 3
      WHEN ls_product-category = 'Audio' THEN 6 ELSE 2 ).
    ls_color-color-int = 0.
    APPEND ls_color TO ls_row-cell_colors.
    APPEND VALUE #( columnname = 'ACTIVE' value = if_salv_c_cell_type=>checkbox ) TO ls_row-cell_types.
    APPEND VALUE #( columnname = 'STATUS' value = if_salv_c_cell_type=>hotspot ) TO ls_row-cell_types.
    APPEND VALUE #( columnname = 'NAME' value = sy-tabix ) TO ls_row-link_handles.
    APPEND ls_row TO gt_rows.
  ENDLOOP.
ENDFORM.

FORM configure_salv USING io_salv TYPE REF TO cl_salv_table.
  DATA lo_columns TYPE REF TO cl_salv_columns_table.
  DATA lo_column TYPE REF TO cl_salv_column.
  DATA lo_functions TYPE REF TO cl_salv_functions_list.
  DATA lo_settings TYPE REF TO cl_salv_display_settings.
  DATA lo_layout TYPE REF TO cl_salv_layout.
  DATA ls_color TYPE lvc_s_colo.
  DATA ls_key TYPE ty_layout_key.

  lo_columns = io_salv->get_columns( ).
  lo_columns->set_optimize( abap_true ).
  lo_columns->set_key_fixation( abap_true ).
  lo_columns->set_column_position( columnname = 'ID' position = 1 ).
  CALL METHOD lo_columns->('SET_COLOR_COLUMN') EXPORTING value = 'CELL_COLORS'.
  CALL METHOD lo_columns->('SET_CELL_TYPE_COLUMN') EXPORTING value = 'CELL_TYPES'.
  CALL METHOD lo_columns->('SET_EXCEPTION_COLUMN') EXPORTING value = 'EXCEPTION'.
  CALL METHOD lo_columns->('SET_HYPERLINK_ENTRY_COLUMN') EXPORTING value = 'LINK_HANDLES'.

  lo_column = lo_columns->get_column( 'ID' ).
  lo_column->set_short_text( 'ID' ).
  lo_column->set_medium_text( 'Product ID' ).
  lo_column->set_long_text( 'Product identifier' ).
  lo_column->set_output_length( 10 ).
  lo_column->set_tooltip( 'Stable demo product identifier' ).
  CALL METHOD lo_column->('SET_KEY') EXPORTING value = abap_true.

  lo_column = lo_columns->get_column( 'NAME' ).
  lo_column->set_long_text( 'Product name (hyperlink)' ).
  lo_column->set_output_length( 28 ).
  lo_column->set_alignment( 1 ).

  lo_column = lo_columns->get_column( 'QUANTITY' ).
  lo_column->set_long_text( 'Available quantity' ).
  lo_column->set_quantity_column( 'UNIT' ).
  lo_column->set_sign( abap_true ).
  lo_column->set_zero( abap_false ).

  lo_column = lo_columns->get_column( 'PRICE' ).
  lo_column->set_long_text( 'Unit price' ).
  lo_column->set_currency_column( 'CURRENCY' ).
  lo_column->set_sign( abap_true ).
  lo_column->set_zero( abap_true ).
  lo_column->set_edit_mask( '==DEC2' ).

  lo_column = lo_columns->get_column( 'CATEGORY' ).
  CLEAR ls_color.
  ls_color-col = 5.
  ls_color-int = 0.
  CALL METHOD lo_column->('SET_COLOR') EXPORTING value = ls_color.

  lo_column = lo_columns->get_column( 'STATUS' ).
  CALL METHOD lo_column->('SET_CELL_TYPE') EXPORTING value = if_salv_c_cell_type=>hotspot.

  lo_column = lo_columns->get_column( 'TECHNICAL' ).
  lo_column->set_technical( abap_true ).
  lo_column = lo_columns->get_column( 'DESCRIPTION' ).
  lo_column->set_visible( abap_false ).

  lo_functions = io_salv->get_functions( ).
  lo_functions->set_all( abap_true ).
  lo_functions->add_function(
    name = 'ZRESET' icon = '@42@' text = 'Reset'
    tooltip = 'Restore deterministic demo rows'
    position = if_salv_c_function_position=>right_of_salv_functions ).
  lo_functions->add_function(
    name = 'ZSELECT' icon = '@0V@' text = 'Selection'
    tooltip = 'Read the selected SALV rows'
    position = if_salv_c_function_position=>right_of_salv_functions ).
  lo_functions->add_function(
    name = 'ZREMOVE' text = 'Temporary' tooltip = 'Function removed before display'
    position = if_salv_c_function_position=>right_of_salv_functions ).
  lo_functions->remove_function( 'ZREMOVE' ).

  io_salv->get_sorts( )->add_sort(
    columnname = 'CATEGORY' sequence = 1 position = 1 subtotal = abap_false ).
  io_salv->get_sorts( )->add_sort(
    columnname = 'NAME' sequence = 1 position = 2 subtotal = abap_false ).
  io_salv->get_filters( )->add_filter(
    columnname = 'CATEGORY' sign = 'I' option = 'CP' low = '*' ).
  io_salv->get_aggregations( )->add_aggregation(
    columnname = 'QUANTITY' aggregation = if_salv_c_aggregation=>total ).
  io_salv->get_aggregations( )->add_aggregation(
    columnname = 'PRICE' aggregation = if_salv_c_aggregation=>average ).

  lo_settings = io_salv->get_display_settings( ).
  lo_settings->set_list_header( 'Read-only SALV product gallery' ).
  lo_settings->set_striped_pattern( abap_true ).
  lo_settings->set_fit_column_to_table_size( abap_true ).
  io_salv->set_selection_mode( if_salv_c_selection_mode=>multiple ).
  io_salv->set_selected_rows( VALUE cl_salv_table=>ty_rows( ( 1 ) ( 3 ) ) ).

  ls_key-report = sy-repid.
  ls_key-handle = 'MAIN'.
  lo_layout = io_salv->get_layout( ).
  lo_layout->set_key( ls_key ).
  lo_layout->set_save_restriction( cl_salv_layout=>restrict_none ).
  lo_layout->set_default( abap_true ).
  lo_layout->set_initial_layout( 'GG_DEFAULT' ).

  PERFORM configure_hyperlinks USING io_salv.
  PERFORM configure_forms USING io_salv.
ENDFORM.

FORM configure_hyperlinks USING io_salv TYPE REF TO cl_salv_table.
  DATA lo_settings TYPE REF TO cl_salv_functional_settings.
  DATA lo_hyperlinks TYPE REF TO cl_salv_hyperlinks.

  lo_settings = io_salv->get_functional_settings( ).
  lo_hyperlinks = lo_settings->get_hyperlinks( ).
  DO lines( gt_rows ) TIMES.
    lo_hyperlinks->add_hyperlink(
      handle = sy-index hyperlink = |https://example.invalid/products/{ sy-index }| ).
  ENDDO.
ENDFORM.

FORM configure_forms USING io_salv TYPE REF TO cl_salv_table.
  DATA lo_top TYPE REF TO object.
  DATA lo_end TYPE REF TO object.
  DATA lv_grid_class TYPE string VALUE 'CL_SALV_FORM_LAYOUT_GRID'.

  CREATE OBJECT lo_top TYPE (lv_grid_class).
  CALL METHOD lo_top->('CREATE_HEADER_INFORMATION')
    EXPORTING row = 1 column = 1 text = 'SALV table sample'
      tooltip = 'Top-of-list form element'.
  CALL METHOD lo_top->('CREATE_LABEL')
    EXPORTING row = 2 column = 1 text = 'Five deterministic products'.

  CREATE OBJECT lo_end TYPE (lv_grid_class).
  CALL METHOD lo_end->('CREATE_LABEL')
    EXPORTING row = 1 column = 1 text = 'End of SALV output'.

  CALL METHOD io_salv->('SET_TOP_OF_LIST') EXPORTING value = lo_top.
  CALL METHOD io_salv->('SET_TOP_OF_LIST_PRINT') EXPORTING value = lo_top.
  CALL METHOD io_salv->('SET_END_OF_LIST') EXPORTING value = lo_end.
ENDFORM.

FORM read_selection.
  IF go_salv IS NOT BOUND.
    gv_status = 'SALV is unavailable; no selected rows can be read'.
    RETURN.
  ENDIF.
  TRY.
      DATA(lt_rows) = go_salv->get_selected_rows( ).
      gv_status = |Selected SALV row count: { lines( lt_rows ) }|.
      gv_detail = COND #( WHEN lt_rows IS INITIAL
        THEN 'Choose rows using the row selector and retry'
        ELSE |First selected row index: { lt_rows[ 1 ] }| ).
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Selection read failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM inspect_layouts.
  DATA ls_key TYPE ty_layout_key.

  ls_key-report = sy-repid.
  ls_key-handle = 'MAIN'.
  TRY.
      DATA(ls_default) = cl_salv_layout_service=>get_default_layout( s_key = ls_key ).
      DATA(lt_layouts) = cl_salv_layout_service=>get_layouts( s_key = ls_key ).
      DATA(ls_chosen) = cl_salv_layout_service=>f4_layouts(
        s_key = ls_key layout = ls_default-layout restrict = cl_salv_layout=>restrict_none ).
      gv_status = |Available layouts: { lines( lt_layouts ) }; F4 returned { ls_chosen-layout }|.
      gv_detail = |Default layout: { ls_default-layout }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Layout service unavailable or canceled: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM export_xml.
  IF go_salv IS NOT BOUND.
    gv_status = 'SALV is unavailable; no XML representation can be exported'.
    RETURN.
  ENDIF.
  TRY.
      DATA(lv_xml) = go_salv->to_xml( xml_type = 1 ).
      gv_status = |TO_XML returned { xstrlen( lv_xml ) } bytes|.
      gv_detail = 'The sample measures the generated representation without writing to a frontend path'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |SALV XML export failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM refresh_data.
  IF go_salv IS NOT BOUND.
    gv_status = 'SALV is unavailable; no table can be refreshed'.
    RETURN.
  ENDIF.
  ADD 1 TO gv_refresh_count.
  READ TABLE gt_rows INDEX 1 ASSIGNING FIELD-SYMBOL(<row>).
  IF sy-subrc = 0.
    <row>-quantity = 12 + gv_refresh_count.
  ENDIF.
  TRY.
      go_salv->refresh( s_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
      gv_status = |Row P100 refreshed in place; quantity is now { <row>-quantity }|.
      gv_detail = 'Stable row and column positions were requested'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |SALV refresh failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM reset_data.
  CLEAR gv_refresh_count.
  PERFORM build_rows.
  IF go_salv IS BOUND.
    TRY.
        go_salv->refresh( s_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
        gv_status = 'Deterministic rows restored and the current SALV refreshed'.
      CATCH cx_root INTO DATA(lx_error).
        gv_status = |SALV reset failed: { lx_error->get_text( ) }|.
    ENDTRY.
  ELSE.
    gv_status = 'Deterministic rows restored; the fallback remains visible'.
  ENDIF.
ENDFORM.

FORM show_popup.
  DATA lo_popup TYPE REF TO cl_salv_table.
  DATA lt_popup TYPE ty_rows.

  lt_popup = gt_rows.
  TRY.
      cl_salv_table=>factory(
        EXPORTING list_display = abap_true
        IMPORTING r_salv_table = lo_popup
        CHANGING t_table       = lt_popup ).
      lo_popup->set_screen_popup(
        start_column = 10 end_column = 100 start_line = 3 end_line = 25 ).
      lo_popup->get_functions( )->set_all( abap_true ).
      lo_popup->display( ).
      gv_status = 'Popup SALV closed and control returned to screen 0100'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Popup SALV unavailable: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM show_fullscreen.
  DATA lo_full TYPE REF TO cl_salv_table.
  DATA lt_full TYPE ty_rows.

  lt_full = gt_rows.
  TRY.
      cl_salv_table=>factory(
        EXPORTING list_display = abap_false
        IMPORTING r_salv_table = lo_full
        CHANGING t_table       = lt_full ).
      lo_full->set_screen_status(
        report = sy-repid pfstatus = 'STANDARD'
        set_functions = cl_salv_table=>c_functions_all ).
      lo_full->display( ).
      gv_status = 'Fullscreen SALV closed and control returned to screen 0100'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Fullscreen SALV unavailable: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM inspect_offline.
  TRY.
      DATA(lv_offline) = cl_salv_table=>is_offline( ).
      gv_status = |CL_SALV_TABLE=>IS_OFFLINE returned { lv_offline }|.
      gv_detail = COND #( WHEN lv_offline = abap_true
        THEN 'List output is required because no online GUI control is available'
        ELSE 'Container, fullscreen, and popup modes can use the active SAP GUI frontend' ).
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Offline capability check failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM show_fallback USING io_error TYPE REF TO cx_root.
  DATA lt_text TYPE ty_text_lines.

  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( 'CL_SALV_TABLE is unavailable or nonfunctional in this runtime.' )
    ( 'The native SAP sample remains syntax checked and guarded by a capability check.' )
    ( 'The pinned open-abap-gui SALV factory currently terminates with an assertion.' ) ).
  go_fallback->set_text_as_r3table( table = lt_text ).
  go_fallback->set_readonly_mode( readonly_mode = 1 ).
  gv_status = 'SALV unavailable; a non-terminating text fallback is displayed'.
  gv_detail = io_error->get_text( ).
ENDFORM.

FORM free_controls.
  FREE: go_events, go_salv.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
