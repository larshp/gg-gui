REPORT zgg_gui_salv_hierseq.

TYPES:
  BEGIN OF ty_header,
    group_id   TYPE c LENGTH 8,
    group_name TYPE c LENGTH 30,
    owner      TYPE c LENGTH 12,
  END OF ty_header,
  ty_headers TYPE STANDARD TABLE OF ty_header WITH EMPTY KEY.

TYPES:
  BEGIN OF ty_item,
    group_id TYPE c LENGTH 8,
    item_id  TYPE c LENGTH 8,
    name     TYPE c LENGTH 30,
    quantity TYPE i,
    price    TYPE p LENGTH 8 DECIMALS 2,
    currency TYPE c LENGTH 3,
  END OF ty_item,
  ty_items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

TYPES:
  ty_text_line TYPE c LENGTH 255,
  ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

DATA gt_headers TYPE ty_headers.
DATA gt_items TYPE ty_items.
DATA gt_bindings TYPE salv_t_hierseq_binding.
DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_hierseq TYPE REF TO cl_salv_hierseq_table.
DATA go_header_columns TYPE REF TO cl_salv_columns_hierseq.
DATA go_item_columns TYPE REF TO cl_salv_columns_hierseq.
DATA go_item_sorts TYPE REF TO cl_salv_sorts.
DATA go_item_filters TYPE REF TO cl_salv_filters.
DATA go_item_aggregations TYPE REF TO cl_salv_aggregations.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_filtered TYPE abap_bool.
DATA gv_native_events_registered TYPE abap_bool.
DATA gv_hierseq_event TYPE c LENGTH 24.
DATA gv_event_level TYPE i.
DATA gv_event_row TYPE i.
DATA gv_event_column TYPE c LENGTH 40.

INCLUDE zgg_native_salv_hseq.

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
    WHEN 'FILTER'.
      PERFORM toggle_filter.
    WHEN 'TOTALS'.
      PERFORM configure_totals.
    WHEN 'COMPARE'.
      PERFORM compare_models.
    WHEN 'RESET'.
      PERFORM reset_data.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  DATA lv_error TYPE string.

  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  IF go_hierseq IS BOUND OR go_fallback IS BOUND.
    RETURN.
  ENDIF.

  PERFORM build_data.
  gt_bindings = VALUE #( ( master = 'GROUP_ID' slave = 'GROUP_ID' ) ).
  TRY.
      PERFORM create_native_hierseq.
      IF go_hierseq IS NOT BOUND.
        lv_error = gv_hierseq_factory_error.
        IF lv_error IS INITIAL.
          lv_error = 'Hierarchical-sequential SALV factory returned no object'.
        ENDIF.
        PERFORM show_fallback USING lv_error.
        RETURN.
      ENDIF.
      PERFORM configure_levels.
      PERFORM register_native_hierseq_events.
      go_hierseq->display( ).
      PERFORM consume_native_hierseq_event.
      IF gv_hierseq_event IS INITIAL.
        IF gv_native_events_registered = abap_true.
          gv_status = 'Hierarchical-sequential SALV displayed with link-click and double-click events'.
        ELSE.
          gv_status = 'Hierarchical-sequential SALV displayed; native event handler unavailable'.
        ENDIF.
        gv_detail = 'GROUP_ID is the explicit master/slave binding; header and item structures remain separate'.
      ENDIF.
    CATCH cx_root INTO DATA(lx_error).
      FREE: go_hierseq, go_header_columns, go_item_columns,
        go_item_sorts, go_item_filters, go_item_aggregations.
      lv_error = lx_error->get_text( ).
      PERFORM show_fallback USING lv_error.
  ENDTRY.
ENDFORM.

FORM build_data.
  gt_headers = VALUE #(
    ( group_id = 'G_INPUT' group_name = 'Input devices' owner = sy-uname )
    ( group_id = 'G_OUTPUT' group_name = 'Output and collaboration' owner = sy-uname ) ).
  gt_items = VALUE #(
    ( group_id = 'G_INPUT' item_id = 'P100' name = 'Mechanical Keyboard'
      quantity = 12 price = '129.90' currency = 'EUR' )
    ( group_id = 'G_INPUT' item_id = 'P110' name = 'Ergonomic Mouse'
      quantity = 7 price = '74.50' currency = 'EUR' )
    ( group_id = 'G_OUTPUT' item_id = 'P200' name = '27 Inch Display'
      quantity = 4 price = '389.00' currency = 'EUR' )
    ( group_id = 'G_OUTPUT' item_id = 'P400' name = 'Conference Speaker'
      quantity = 9 price = '159.00' currency = 'EUR' ) ).
ENDFORM.

FORM configure_levels.
  DATA lo_column TYPE REF TO cl_salv_column.
  DATA lo_column_list TYPE REF TO cl_salv_column_list.
  DATA lo_functions TYPE REF TO cl_salv_functions_list.

  TRY.
      go_header_columns = go_hierseq->get_columns( 1 ).
      go_item_columns = go_hierseq->get_columns( 2 ).
      go_header_columns->set_optimize( abap_true ).
      go_item_columns->set_optimize( abap_true ).

      lo_column = go_header_columns->get_column( 'GROUP_ID' ).
      lo_column->set_technical( abap_true ).
      lo_column = go_header_columns->get_column( 'GROUP_NAME' ).
      lo_column->set_long_text( 'Product group' ).

      lo_column = go_item_columns->get_column( 'GROUP_ID' ).
      lo_column->set_technical( abap_true ).
      lo_column = go_item_columns->get_column( 'ITEM_ID' ).
      lo_column_list ?= lo_column.
      lo_column_list->set_key( abap_true ).
      lo_column_list->set_cell_type( if_salv_c_cell_type=>hotspot ).
      lo_column = go_item_columns->get_column( 'PRICE' ).
      lo_column->set_currency_column( 'CURRENCY' ).

      lo_functions = go_hierseq->get_functions( ).
      lo_functions->set_all( abap_true ).
      go_item_sorts = go_hierseq->get_sorts( 2 ).
      go_item_filters = go_hierseq->get_filters( 2 ).
      go_item_aggregations = go_hierseq->get_aggregations( 2 ).
      go_item_sorts->add_sort( columnname = 'NAME'
                               sequence   = 1
                               position   = 1
                               subtotal   = abap_false ).
      go_item_filters->add_filter( columnname = 'QUANTITY'
                                   sign       = 'I'
                                   option     = 'GE'
                                   low        = 0 ).
      go_item_aggregations->add_aggregation(
        columnname  = 'QUANTITY'
        aggregation = if_salv_c_aggregation=>total ).
      go_item_aggregations->add_aggregation(
        columnname  = 'PRICE'
        aggregation = if_salv_c_aggregation=>average ).
    CATCH cx_salv_error INTO DATA(lx_levels).
      gv_status = |Hierseq level setup failed: { lx_levels->get_text( ) }|.
  ENDTRY.
ENDFORM.


FORM consume_native_hierseq_event.
  CLEAR: gv_hierseq_event, gv_event_level, gv_event_row, gv_event_column.
  IMPORT event = gv_hierseq_event level = gv_event_level row = gv_event_row
    column = gv_event_column FROM MEMORY ID 'ZGG_GUI_SALV_HIERSEQ_EVENT'.
  FREE MEMORY ID 'ZGG_GUI_SALV_HIERSEQ_EVENT'.
  IF gv_hierseq_event IS NOT INITIAL.
    gv_status = |Hierseq { gv_hierseq_event } at level { gv_event_level }, row { gv_event_row }|.
    gv_detail = |Event column: { gv_event_column }|.
  ENDIF.
ENDFORM.


FORM toggle_filter.
  IF go_item_filters IS NOT BOUND.
    gv_status = 'Hierarchical-sequential SALV is unavailable; filters cannot be changed'.
    RETURN.
  ENDIF.
  gv_filtered = xsdbool( gv_filtered = abap_false ).
  TRY.
      go_item_filters->clear( ).
      IF gv_filtered = abap_true.
        go_item_filters->add_filter( columnname = 'QUANTITY'
                                     sign       = 'I'
                                     option     = 'GE'
                                     low        = 8 ).
      ELSE.
        go_item_filters->add_filter( columnname = 'QUANTITY'
                                     sign       = 'I'
                                     option     = 'GE'
                                     low        = 0 ).
      ENDIF.
      go_hierseq->refresh( ).
      gv_status = |Item-level quantity filter toggled; threshold-eight mode { gv_filtered }|.
      gv_detail = 'Header rows remain linked to their surviving item rows through the GROUP_ID binding'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Hierarchical-sequential filter failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM configure_totals.
  IF go_item_aggregations IS NOT BOUND.
    gv_status = 'Hierarchical-sequential SALV is unavailable; aggregations cannot be changed'.
    RETURN.
  ENDIF.
  TRY.
      go_item_sorts->clear( ).
      go_item_sorts->add_sort( columnname = 'NAME'
                               sequence   = 1
                               position   = 1
                               subtotal   = abap_false ).
      go_item_aggregations->add_aggregation(
        columnname  = 'QUANTITY'
        aggregation = if_salv_c_aggregation=>maximum ).
      go_hierseq->refresh( ).
      gv_status = 'Item sorting restored; total quantity, average price, and maximum quantity aggregations requested'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Hierarchical-sequential aggregation failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM compare_models.
  DATA lv_salv_available TYPE abap_bool.
  DATA lo_descr TYPE REF TO cl_abap_typedescr.

  TRY.
      lo_descr = cl_abap_classdescr=>describe_by_name( 'CL_SALV_HIERSEQ_TABLE' ).
      lv_salv_available = xsdbool( lo_descr IS BOUND ).
    CATCH cx_root.
      lv_salv_available = abap_false.
  ENDTRY.
  gv_status = |CL_SALV_HIERSEQ_TABLE available on this system: { lv_salv_available }|.
  gv_detail = 'Hierseq fits fixed two-level master/detail output; ordinary tables lack grouping and trees support arbitrary depth'.
ENDFORM.

FORM reset_data.
  CLEAR gv_filtered.
  PERFORM build_data.
  IF go_hierseq IS BOUND.
    TRY.
        go_item_filters->clear( ).
        go_item_filters->add_filter( columnname = 'QUANTITY'
                                     sign       = 'I'
                                     option     = 'GE'
                                     low        = 0 ).
        go_hierseq->refresh( ).
        gv_status = 'Header rows, item rows, binding assumptions, filter, and displayed hierarchy reset'.
      CATCH cx_root INTO DATA(lx_error).
        gv_status = |Hierarchical-sequential reset failed: { lx_error->get_text( ) }|.
    ENDTRY.
  ENDIF.
ENDFORM.

FORM show_fallback USING iv_error TYPE string.
  DATA lt_text TYPE ty_text_lines.

  IF go_fallback IS BOUND.
    RETURN.
  ENDIF.
  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( 'CL_SALV_HIERSEQ_TABLE and its helper classes are unavailable in this runtime.' )
    ( 'The native SAP sample retains factory bindings and separate level configuration behind capability checks.' )
    ( 'Static event handlers require the missing hierarchical-sequential SALV event class.' ) ).
  go_fallback->set_text_as_r3table( lt_text ).
  go_fallback->set_readonly_mode( 1 ).
  gv_status = 'Hierarchical-sequential SALV unavailable; a text fallback is displayed'.
  gv_detail = iv_error.
ENDFORM.

FORM free_controls.
  PERFORM unregister_hierseq_events.
  FREE: go_header_columns, go_item_columns, go_item_sorts,
    go_item_filters, go_item_aggregations, go_hierseq.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
