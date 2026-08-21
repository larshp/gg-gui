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
  BEGIN OF ty_binding,
    master TYPE lvc_fname,
    slave  TYPE lvc_fname,
  END OF ty_binding,
  ty_bindings TYPE STANDARD TABLE OF ty_binding WITH EMPTY KEY,
  ty_text_line TYPE c LENGTH 255,
  ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

DATA gt_headers TYPE ty_headers.
DATA gt_items TYPE ty_items.
DATA gt_bindings TYPE ty_bindings.
DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_hierseq TYPE REF TO object.
DATA go_header_columns TYPE REF TO object.
DATA go_item_columns TYPE REF TO object.
DATA go_item_sorts TYPE REF TO object.
DATA go_item_filters TYPE REF TO object.
DATA go_item_aggregations TYPE REF TO object.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_filtered TYPE abap_bool.
DATA gv_native_event_program TYPE c LENGTH 8.
DATA gv_native_events_registered TYPE abap_bool.
DATA gv_hierseq_event TYPE c LENGTH 24.
DATA gv_event_level TYPE i.
DATA gv_event_row TYPE i.
DATA gv_event_column TYPE c LENGTH 40.

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
  DATA lv_class TYPE string VALUE 'CL_SALV_HIERSEQ_TABLE'.
  DATA lv_factory TYPE string VALUE 'FACTORY'.
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
      CALL METHOD (lv_class)=>(lv_factory)
        EXPORTING t_binding_level1_level2 = gt_bindings
        IMPORTING r_hierseq = go_hierseq
        CHANGING t_table_level1 = gt_headers t_table_level2 = gt_items.
      IF go_hierseq IS NOT BOUND.
        PERFORM show_fallback USING 'Hierarchical-sequential SALV factory returned no object'.
        RETURN.
      ENDIF.
      PERFORM configure_levels.
      PERFORM register_native_hierseq_events.
      CALL METHOD go_hierseq->('DISPLAY').
      PERFORM consume_native_hierseq_event.
      IF gv_hierseq_event IS INITIAL.
        IF gv_native_events_registered = abap_true.
          gv_status = 'Hierarchical-sequential SALV displayed with link-click and double-click events'.
        ELSE.
          gv_status = 'Hierarchical-sequential SALV displayed; native event adapter unavailable'.
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
  DATA lo_column TYPE REF TO object.
  DATA lo_functions TYPE REF TO object.

  CALL METHOD go_hierseq->('GET_COLUMNS') EXPORTING level = 1 RECEIVING value = go_header_columns.
  CALL METHOD go_hierseq->('GET_COLUMNS') EXPORTING level = 2 RECEIVING value = go_item_columns.
  CALL METHOD go_header_columns->('SET_OPTIMIZE') EXPORTING value = abap_true.
  CALL METHOD go_item_columns->('SET_OPTIMIZE') EXPORTING value = abap_true.

  CALL METHOD go_header_columns->('GET_COLUMN') EXPORTING columnname = 'GROUP_ID' RECEIVING value = lo_column.
  CALL METHOD lo_column->('SET_TECHNICAL') EXPORTING value = abap_true.
  CALL METHOD go_header_columns->('GET_COLUMN') EXPORTING columnname = 'GROUP_NAME' RECEIVING value = lo_column.
  CALL METHOD lo_column->('SET_LONG_TEXT') EXPORTING value = 'Product group'.

  CALL METHOD go_item_columns->('GET_COLUMN') EXPORTING columnname = 'GROUP_ID' RECEIVING value = lo_column.
  CALL METHOD lo_column->('SET_TECHNICAL') EXPORTING value = abap_true.
  CALL METHOD go_item_columns->('GET_COLUMN') EXPORTING columnname = 'ITEM_ID' RECEIVING value = lo_column.
  CALL METHOD lo_column->('SET_KEY') EXPORTING value = abap_true.
  CALL METHOD lo_column->('SET_CELL_TYPE') EXPORTING value = if_salv_c_cell_type=>hotspot.
  CALL METHOD go_item_columns->('GET_COLUMN') EXPORTING columnname = 'PRICE' RECEIVING value = lo_column.
  CALL METHOD lo_column->('SET_CURRENCY_COLUMN') EXPORTING value = 'CURRENCY'.

  CALL METHOD go_hierseq->('GET_FUNCTIONS') RECEIVING value = lo_functions.
  CALL METHOD lo_functions->('SET_ALL') EXPORTING value = abap_true.
  CALL METHOD go_hierseq->('GET_SORTS') EXPORTING level = 2 RECEIVING value = go_item_sorts.
  CALL METHOD go_hierseq->('GET_FILTERS') EXPORTING level = 2 RECEIVING value = go_item_filters.
  CALL METHOD go_hierseq->('GET_AGGREGATIONS') EXPORTING level = 2 RECEIVING value = go_item_aggregations.
  CALL METHOD go_item_sorts->('ADD_SORT')
    EXPORTING columnname = 'NAME' sequence = 1 position = 1 subtotal = abap_false.
  CALL METHOD go_item_filters->('ADD_FILTER')
    EXPORTING columnname = 'QUANTITY' sign = 'I' option = 'GE' low = 0.
  CALL METHOD go_item_aggregations->('ADD_AGGREGATION')
    EXPORTING columnname = 'QUANTITY' aggregation = if_salv_c_aggregation=>total.
  CALL METHOD go_item_aggregations->('ADD_AGGREGATION')
    EXPORTING columnname = 'PRICE' aggregation = if_salv_c_aggregation=>average.
ENDFORM.

FORM register_native_hierseq_events.
  DATA lt_source TYPE STANDARD TABLE OF string WITH EMPTY KEY.
  DATA lv_message TYPE string.

  IF gv_native_event_program IS INITIAL.
    lt_source = VALUE #(
      ( `PROGRAM SUBPOOL.` )
      ( `CLASS lcl_events DEFINITION DEFERRED.` )
      ( `DATA go_events TYPE REF TO lcl_events.` )
      ( `DATA go_hierseq TYPE REF TO cl_salv_hierseq_table.` )
      ( `DATA go_salv_events TYPE REF TO cl_salv_events_hierseq.` )
      ( `CLASS lcl_events DEFINITION.` )
      ( `  PUBLIC SECTION.` )
      ( `    METHODS on_link FOR EVENT link_click OF cl_salv_events_hierseq` )
      ( `      IMPORTING level row column.` )
      ( `    METHODS on_double FOR EVENT double_click OF cl_salv_events_hierseq` )
      ( `      IMPORTING level row column.` )
      ( `ENDCLASS.` )
      ( `CLASS lcl_events IMPLEMENTATION.` )
      ( `  METHOD on_link.` )
      ( `    DATA lv_event TYPE c LENGTH 24 VALUE 'LINK_CLICK'.` )
      ( `    DATA lv_text TYPE c LENGTH 80.` )
      ( `    EXPORT event = lv_event level = level row = row column = column` )
      ( `      TO MEMORY ID 'ZGG_GUI_SALV_HIERSEQ_EVENT'.` )
      ( `    lv_text = |LINK_CLICK level { level }, row { row }, column { column }|.` )
      ( `    MESSAGE lv_text TYPE 'S'.` )
      ( `  ENDMETHOD.` )
      ( `  METHOD on_double.` )
      ( `    DATA lv_event TYPE c LENGTH 24 VALUE 'DOUBLE_CLICK'.` )
      ( `    DATA lv_text TYPE c LENGTH 80.` )
      ( `    EXPORT event = lv_event level = level row = row column = column` )
      ( `      TO MEMORY ID 'ZGG_GUI_SALV_HIERSEQ_EVENT'.` )
      ( `    lv_text = |DOUBLE_CLICK level { level }, row { row }, column { column }|.` )
      ( `    MESSAGE lv_text TYPE 'S'.` )
      ( `  ENDMETHOD.` )
      ( `ENDCLASS.` )
      ( `FORM register USING io_hierseq TYPE REF TO object` )
      ( `    CHANGING cv_registered TYPE abap_bool.` )
      ( `  CLEAR cv_registered.` )
      ( `  go_hierseq ?= io_hierseq.` )
      ( `  go_salv_events = go_hierseq->get_event( ).` )
      ( `  CREATE OBJECT go_events.` )
      ( `  SET HANDLER go_events->on_link FOR go_salv_events.` )
      ( `  SET HANDLER go_events->on_double FOR go_salv_events.` )
      ( `  cv_registered = abap_true.` )
      ( `ENDFORM.` )
      ( `FORM unregister.` )
      ( `  IF go_events IS BOUND AND go_salv_events IS BOUND.` )
      ( `    SET HANDLER go_events->on_link FOR go_salv_events ACTIVATION space.` )
      ( `    SET HANDLER go_events->on_double FOR go_salv_events ACTIVATION space.` )
      ( `  ENDIF.` )
      ( `  FREE: go_events, go_salv_events, go_hierseq.` )
      ( `ENDFORM.` ) ).

    GENERATE SUBROUTINE POOL lt_source
      NAME gv_native_event_program MESSAGE lv_message.
    IF sy-subrc <> 0 OR gv_native_event_program IS INITIAL.
      CLEAR: gv_native_event_program, gv_native_events_registered.
      gv_detail = |Native hierseq event adapter did not compile: { lv_message }|.
      RETURN.
    ENDIF.
  ENDIF.

  TRY.
      PERFORM register IN PROGRAM (gv_native_event_program)
        USING go_hierseq CHANGING gv_native_events_registered.
    CATCH cx_root INTO DATA(lx_event_error).
      CLEAR gv_native_events_registered.
      gv_detail = |Native hierseq event registration failed: { lx_event_error->get_text( ) }|.
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

FORM unregister_native_hierseq_events.
  IF gv_native_event_program IS NOT INITIAL AND
      gv_native_events_registered = abap_true.
    TRY.
        PERFORM unregister IN PROGRAM (gv_native_event_program) IF FOUND.
      CATCH cx_root.
    ENDTRY.
  ENDIF.
  CLEAR gv_native_events_registered.
  FREE MEMORY ID 'ZGG_GUI_SALV_HIERSEQ_EVENT'.
ENDFORM.

FORM toggle_filter.
  IF go_item_filters IS NOT BOUND.
    gv_status = 'Hierarchical-sequential SALV is unavailable; filters cannot be changed'.
    RETURN.
  ENDIF.
  gv_filtered = xsdbool( gv_filtered = abap_false ).
  TRY.
      CALL METHOD go_item_filters->('CLEAR').
      IF gv_filtered = abap_true.
        CALL METHOD go_item_filters->('ADD_FILTER')
          EXPORTING columnname = 'QUANTITY' sign = 'I' option = 'GE' low = 8.
      ELSE.
        CALL METHOD go_item_filters->('ADD_FILTER')
          EXPORTING columnname = 'QUANTITY' sign = 'I' option = 'GE' low = 0.
      ENDIF.
      CALL METHOD go_hierseq->('REFRESH').
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
      CALL METHOD go_item_sorts->('CLEAR').
      CALL METHOD go_item_sorts->('ADD_SORT')
        EXPORTING columnname = 'NAME' sequence = 1 position = 1 subtotal = abap_false.
      CALL METHOD go_item_aggregations->('ADD_AGGREGATION')
        EXPORTING columnname = 'QUANTITY' aggregation = if_salv_c_aggregation=>maximum.
      CALL METHOD go_hierseq->('REFRESH').
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
        CALL METHOD go_item_filters->('CLEAR').
        CALL METHOD go_item_filters->('ADD_FILTER')
          EXPORTING columnname = 'QUANTITY' sign = 'I' option = 'GE' low = 0.
        CALL METHOD go_hierseq->('REFRESH').
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
  go_fallback->set_text_as_r3table( table = lt_text ).
  go_fallback->set_readonly_mode( readonly_mode = 1 ).
  gv_status = 'Hierarchical-sequential SALV unavailable; a text fallback is displayed'.
  gv_detail = iv_error.
ENDFORM.

FORM free_controls.
  PERFORM unregister_native_hierseq_events.
  CLEAR gv_native_event_program.
  FREE: go_header_columns, go_item_columns, go_item_sorts,
    go_item_filters, go_item_aggregations, go_hierseq.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
