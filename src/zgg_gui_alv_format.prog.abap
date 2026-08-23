REPORT zgg_gui_alv_format.

TYPES:
  BEGIN OF ty_row,
    id          TYPE c LENGTH 8,
    name        TYPE c LENGTH 30,
    category    TYPE c LENGTH 20,
    quantity    TYPE p LENGTH 8 DECIMALS 3,
    unit        TYPE c LENGTH 3,
    price       TYPE p LENGTH 8 DECIMALS 2,
    currency    TYPE c LENGTH 3,
    delivery_on TYPE d,
    delivery_at TYPE t,
    icon        TYPE c LENGTH 4,
    symbol      TYPE c LENGTH 1,
    exception   TYPE i,
    row_color   TYPE c LENGTH 4,
    action      TYPE c LENGTH 12,
    cell_colors TYPE lvc_t_scol,
    styles      TYPE lvc_t_styl,
  END OF ty_row,
  ty_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY,
  ty_text_line TYPE c LENGTH 255,
  ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

DATA gt_rows TYPE ty_rows.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA gt_sort TYPE lvc_t_sort.
DATA gt_groups TYPE lvc_t_sgrp.
DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_alternate TYPE abap_bool.

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
    WHEN 'COLORS'.
      PERFORM toggle_colors.
    WHEN 'STYLES'.
      PERFORM toggle_styles.
    WHEN 'SYMBOLS'.
      PERFORM toggle_symbols.
    WHEN 'GROUPS'.
      PERFORM toggle_groups.
    WHEN 'TOTALS'.
      PERFORM inspect_totals.
    WHEN 'RESET'.
      PERFORM reset_formatting.
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
  PERFORM build_field_catalog.
  PERFORM build_groups_and_sort.
  TRY.
      CREATE OBJECT go_grid EXPORTING i_parent = go_host.
      go_grid->set_table_for_first_display(
        EXPORTING is_layout = VALUE lvc_s_layo(
          zebra = abap_true cwidth_opt = abap_true no_keyfix = abap_false
          ctab_fname = 'CELL_COLORS' info_fname = 'ROW_COLOR'
          stylefname = 'STYLES' excp_fname = 'EXCEPTION' excp_led = abap_true
          totals_bef = abap_true grid_title = 'ALV presentation features' )
          it_special_groups = gt_groups
        CHANGING it_outtab = gt_rows it_fieldcatalog = gt_fieldcat it_sort = gt_sort ).
      gv_status = 'Formatted ALV created with row, column, and cell colors; styles; icons; traffic lights; groups; and totals'.
      gv_detail = 'Currency, quantity, unit, date, time, and decimal fields use explicit LVC references and output settings'.
    CATCH cx_root INTO DATA(lx_error).
      FREE go_grid.
      PERFORM show_fallback USING lx_error.
  ENDTRY.
ENDFORM.

FORM build_rows.
  DATA lt_products TYPE zcl_gg_gui_demo_data=>ty_products.
  DATA ls_cell_color TYPE lvc_s_scol.

  CLEAR gt_rows.
  lt_products = zcl_gg_gui_demo_data=>products( ).
  LOOP AT lt_products INTO DATA(ls_product).
    DATA(ls_row) = VALUE ty_row(
      id = ls_product-id name = ls_product-name category = ls_product-category
      quantity = ls_product-quantity unit = 'EA' price = ls_product-price
      currency = ls_product-currency delivery_on = sy-datum + sy-tabix
      delivery_at = sy-uzeit icon = COND #( WHEN ls_product-active = abap_true THEN '@01@' ELSE '@02@' )
      symbol = COND #( WHEN ls_product-quantity > 0 THEN '+' ELSE '-' )
      exception = COND #( WHEN ls_product-quantity = 0 THEN 1
        WHEN ls_product-quantity < 5 THEN 2 ELSE 3 )
      row_color = COND #( WHEN ls_product-active = abap_false THEN 'C210' ELSE space )
      action = 'Inspect' ).

    ls_cell_color-fname = 'CATEGORY'.
    ls_cell_color-color-col = COND #(
      WHEN ls_product-category = 'Input' THEN 5
      WHEN ls_product-category = 'Display' THEN 3
      WHEN ls_product-category = 'Audio' THEN 6 ELSE 2 ).
    ls_cell_color-color-int = 0.
    APPEND ls_cell_color TO ls_row-cell_colors.
    APPEND VALUE #( fieldname = 'ACTION' style = cl_gui_alv_grid=>mc_style_button ) TO ls_row-styles.
    IF ls_product-active = abap_false.
      APPEND VALUE #( fieldname = 'QUANTITY' style = cl_gui_alv_grid=>mc_style_disabled ) TO ls_row-styles.
    ENDIF.
    APPEND ls_row TO gt_rows.
  ENDLOOP.
ENDFORM.

FORM build_field_catalog.
  gt_fieldcat = VALUE #(
    ( fieldname = 'ID' col_pos = 1 coltext = 'Product ID' key = abap_true
      fix_column = abap_true outputlen = 10 sp_group = 'IDENT' )
    ( fieldname = 'NAME' col_pos = 2 coltext = 'Product name' outputlen = 28
      emphasize = 'C510' sp_group = 'IDENT' )
    ( fieldname = 'CATEGORY' col_pos = 3 coltext = 'Category' outputlen = 18 sp_group = 'IDENT' )
    ( fieldname = 'QUANTITY' col_pos = 4 coltext = 'Quantity' qfieldname = 'UNIT'
      do_sum = abap_true decimals_o = 3 outputlen = 13 sp_group = 'VALUE' )
    ( fieldname = 'UNIT' col_pos = 5 coltext = 'Unit' outputlen = 5 sp_group = 'VALUE' )
    ( fieldname = 'PRICE' col_pos = 6 coltext = 'Unit price' cfieldname = 'CURRENCY'
      do_sum = abap_true decimals_o = 2 outputlen = 14 sp_group = 'VALUE' )
    ( fieldname = 'CURRENCY' col_pos = 7 coltext = 'Currency' outputlen = 8 sp_group = 'VALUE' )
    ( fieldname = 'DELIVERY_ON' col_pos = 8 coltext = 'Date' datatype = 'DATS'
      inttype = 'D' outputlen = 10 sp_group = 'SCHEDULE' )
    ( fieldname = 'DELIVERY_AT' col_pos = 9 coltext = 'Time' datatype = 'TIMS'
      inttype = 'T' outputlen = 8 sp_group = 'SCHEDULE' )
    ( fieldname = 'ICON' col_pos = 10 coltext = 'Icon' icon = abap_true outputlen = 5 sp_group = 'STATE' )
    ( fieldname = 'SYMBOL' col_pos = 11 coltext = 'Symbol' symbol = abap_true outputlen = 6 sp_group = 'STATE' )
    ( fieldname = 'EXCEPTION' col_pos = 12 coltext = 'Light' outputlen = 6 sp_group = 'STATE' )
    ( fieldname = 'ACTION' col_pos = 13 coltext = 'Style button' outputlen = 12 sp_group = 'STATE' ) ).
ENDFORM.

FORM build_groups_and_sort.
  gt_groups = VALUE #(
    ( sp_group = 'IDENT' text = 'Identification' )
    ( sp_group = 'VALUE' text = 'Amounts and units' )
    ( sp_group = 'SCHEDULE' text = 'Schedule' )
    ( sp_group = 'STATE' text = 'Visual state' ) ).
  gt_sort = VALUE #(
    ( spos = 1 fieldname = 'CATEGORY' up = abap_true subtot = abap_true )
    ( spos = 2 fieldname = 'NAME' up = abap_true ) ).
ENDFORM.

FORM toggle_colors.
  gv_alternate = xsdbool( gv_alternate = abap_false ).
  LOOP AT gt_rows ASSIGNING FIELD-SYMBOL(<row>).
    <row>-row_color = COND #( WHEN gv_alternate = abap_true THEN 'C610'
      WHEN <row>-quantity = 0 THEN 'C210' ELSE space ).
    READ TABLE <row>-cell_colors INDEX 1 ASSIGNING FIELD-SYMBOL(<cell_color>).
    IF sy-subrc = 0.
      <cell_color>-color-col = COND #( WHEN gv_alternate = abap_true THEN 7 ELSE 5 ).
      <cell_color>-color-int = COND #( WHEN gv_alternate = abap_true THEN 1 ELSE 0 ).
    ENDIF.
  ENDLOOP.
  PERFORM refresh_grid.
  gv_status = |Row and category-cell color scheme toggled; alternate palette { gv_alternate }|.
ENDFORM.

FORM toggle_styles.
  LOOP AT gt_rows ASSIGNING FIELD-SYMBOL(<row>).
    READ TABLE <row>-styles ASSIGNING FIELD-SYMBOL(<style>) WITH KEY fieldname = 'QUANTITY'.
    IF sy-subrc = 0.
      <style>-style = COND #( WHEN <style>-style = cl_gui_alv_grid=>mc_style_disabled
        THEN cl_gui_alv_grid=>mc_style_enabled ELSE cl_gui_alv_grid=>mc_style_disabled ).
    ELSE.
      APPEND VALUE #( fieldname = 'QUANTITY' style = cl_gui_alv_grid=>mc_style_disabled ) TO <row>-styles.
    ENDIF.
  ENDLOOP.
  PERFORM refresh_grid.
  gv_status = 'Per-cell quantity styles toggled while ACTION remains rendered as a button'.
ENDFORM.

FORM toggle_symbols.
  LOOP AT gt_rows ASSIGNING FIELD-SYMBOL(<row>).
    <row>-icon = COND #( WHEN <row>-icon = '@01@' THEN '@02@' ELSE '@01@' ).
    <row>-symbol = COND #( WHEN <row>-symbol = '+' THEN '-' ELSE '+' ).
    <row>-exception = COND #( WHEN <row>-exception = 3 THEN 1 ELSE <row>-exception + 1 ).
  ENDLOOP.
  PERFORM refresh_grid.
  gv_status = 'Icon identifiers, symbol characters, and exception traffic-light values cycled in place'.
ENDFORM.

FORM toggle_groups.
  DATA lt_frontend TYPE lvc_t_fcat.

  IF go_grid IS NOT BOUND.
    RETURN.
  ENDIF.
  TRY.
      go_grid->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = lt_frontend ).
      LOOP AT lt_frontend ASSIGNING FIELD-SYMBOL(<field>).
        IF <field>-fieldname = 'DESCRIPTION'.
          CONTINUE.
        ENDIF.
        <field>-sp_group = COND #( WHEN <field>-sp_group IS INITIAL THEN 'STATE' ELSE space ).
      ENDLOOP.
      go_grid->set_frontend_fieldcatalog( lt_frontend ).
      gv_status = |Special column-group assignments toggled for { lines( lt_frontend ) } frontend fields|.
      gv_detail = 'The group definitions remain available for the standard Choose Layout dialog'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Column-group toggle failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM inspect_totals.
  DATA lt_sorts TYPE lvc_t_sort.
  DATA lt_groups TYPE lvc_t_grpl.
  DATA lr_totals TYPE REF TO data.

  IF go_grid IS NOT BOUND.
    RETURN.
  ENDIF.
  TRY.
      go_grid->get_sort_criteria( IMPORTING et_sort = lt_sorts ).
      go_grid->get_subtotals( IMPORTING ep_collect00 = lr_totals et_grouplevels = lt_groups ).
      gv_status = |Total fields 2; sort/subtotal rules { lines( lt_sorts ) }; calculated group levels { lines( lt_groups ) }|.
      gv_detail = |Subtotal data reference bound: { xsdbool( lr_totals IS BOUND ) }; fixed key column: ID|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Totals inspection failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM reset_formatting.
  CLEAR gv_alternate.
  PERFORM build_rows.
  PERFORM build_field_catalog.
  IF go_grid IS BOUND.
    TRY.
        go_grid->set_frontend_fieldcatalog( gt_fieldcat ).
        go_grid->set_sort_criteria( gt_sort ).
        PERFORM refresh_grid.
        gv_status = 'Rows, colors, styles, symbols, groups, fixed columns, totals, and subtotals reset'.
      CATCH cx_root INTO DATA(lx_error).
        gv_status = |Formatting reset failed: { lx_error->get_text( ) }|.
    ENDTRY.
  ENDIF.
ENDFORM.

FORM refresh_grid.
  IF go_grid IS BOUND.
    go_grid->refresh_table_display(
      is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
  ENDIF.
ENDFORM.

FORM show_fallback USING io_error TYPE REF TO cx_root.
  DATA lt_text TYPE ty_text_lines.

  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( 'Formatted CL_GUI_ALV_GRID output is unavailable in this runtime.' )
    ( 'The native SAP report retains its LVC color, style, group, format, total, and subtotal setup.' )
    ( 'The pinned open-abap-gui ALV Grid constructor currently terminates with an assertion.' ) ).
  go_fallback->set_text_as_r3table( lt_text ).
  go_fallback->set_readonly_mode( 1 ).
  gv_status = 'Formatted ALV unavailable; a non-terminating text fallback is displayed'.
  gv_detail = io_error->get_text( ).
ENDFORM.

FORM free_controls.
  IF go_grid IS BOUND. go_grid->free( ). FREE go_grid. ENDIF.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
