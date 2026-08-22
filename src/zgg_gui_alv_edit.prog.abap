REPORT zgg_gui_alv_edit.

TYPES:
  BEGIN OF ty_row,
    id       TYPE c LENGTH 8,
    name     TYPE c LENGTH 30,
    category TYPE c LENGTH 20,
    quantity TYPE i,
    price    TYPE p LENGTH 8 DECIMALS 2,
    currency TYPE c LENGTH 3,
    active   TYPE abap_bool,
    choice   TYPE c LENGTH 12,
    action   TYPE c LENGTH 12,
    styles   TYPE lvc_t_styl,
  END OF ty_row,
  ty_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY,
  ty_f4_value TYPE c LENGTH 30,
  ty_f4_values TYPE STANDARD TABLE OF ty_f4_value WITH EMPTY KEY,
  ty_text_line TYPE c LENGTH 255,
  ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

CLASS lcl_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_data_changed FOR EVENT data_changed OF cl_gui_alv_grid
      IMPORTING er_data_changed e_onf4 e_onf4_before e_onf4_after e_ucomm.
    METHODS on_data_changed_finished FOR EVENT data_changed_finished OF cl_gui_alv_grid
      IMPORTING e_modified et_good_cells.
    METHODS on_button_click FOR EVENT button_click OF cl_gui_alv_grid
      IMPORTING es_col_id es_row_no.
    METHODS on_f4 FOR EVENT onf4 OF cl_gui_alv_grid
      IMPORTING e_fieldname e_fieldvalue es_row_no er_event_data et_bad_cells e_display.
ENDCLASS.

DATA gt_rows TYPE ty_rows.
DATA gt_saved_rows TYPE ty_rows.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA go_events TYPE REF TO lcl_events.
DATA go_protocol TYPE REF TO cl_alv_changed_data_protocol.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_next_id TYPE i VALUE 500.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_data_changed.
    go_protocol = er_data_changed.
    LOOP AT er_data_changed->mt_mod_cells INTO DATA(ls_cell).
      IF ls_cell-fieldname = 'QUANTITY' AND ls_cell-value < 0.
        er_data_changed->add_protocol_entry(
          i_msgid     = '00'
          i_msgty     = 'E'
          i_msgno     = '398'
          i_msgv1     = 'Quantity must be zero or greater'
          i_fieldname = ls_cell-fieldname
          i_row_id    = ls_cell-row_id ).
        er_data_changed->modify_cell(
          i_row_id    = ls_cell-row_id
          i_fieldname = ls_cell-fieldname
          i_value     = 0 ).
        er_data_changed->modify_style(
          i_row_id    = ls_cell-row_id
          i_fieldname = ls_cell-fieldname
          i_style     = cl_gui_alv_grid=>mc_style_disabled ).
      ELSEIF ls_cell-fieldname = 'NAME' AND ls_cell-value IS INITIAL.
        er_data_changed->add_protocol_entry(
          i_msgid     = '00'
          i_msgty     = 'E'
          i_msgno     = '398'
          i_msgv1     = 'Product name is required'
          i_fieldname = ls_cell-fieldname
          i_row_id    = ls_cell-row_id ).
      ELSEIF ls_cell-fieldname = 'PRICE' AND ls_cell-value < 0.
        er_data_changed->add_protocol_entry(
          i_msgid     = '00'
          i_msgty     = 'E'
          i_msgno     = '398'
          i_msgv1     = 'Price must be zero or greater'
          i_fieldname = ls_cell-fieldname
          i_row_id    = ls_cell-row_id ).
      ENDIF.
    ENDLOOP.
    DATA lv_id TYPE c LENGTH 8.
    IF er_data_changed->mt_mod_cells IS NOT INITIAL.
      READ TABLE er_data_changed->mt_mod_cells INDEX 1 INTO DATA(ls_first).
      er_data_changed->get_cell_value(
        EXPORTING i_row_id    = ls_first-row_id
                  i_fieldname = 'ID'
        IMPORTING e_value     = lv_id ).
      er_data_changed->refresh_protocol( ).
      gv_detail = |Protocol refreshed for row { ls_first-row_id }, product { lv_id }, command { e_ucomm }|.
    ENDIF.
    gv_status = |DATA_CHANGED received { lines( er_data_changed->mt_mod_cells ) } modified cells; F4 before/after { e_onf4_before }/{ e_onf4_after }|.
  ENDMETHOD.

  METHOD on_data_changed_finished.
    gv_status = |DATA_CHANGED_FINISHED: modified { e_modified }, accepted cells { lines( et_good_cells ) }|.
    gv_detail = COND #( WHEN gt_rows = gt_saved_rows
      THEN 'Working rows match the in-memory saved snapshot'
      ELSE 'Unsaved in-memory edits exist' ).
  ENDMETHOD.

  METHOD on_button_click.
    READ TABLE gt_rows INDEX es_row_no-row_id ASSIGNING FIELD-SYMBOL(<row>).
    IF sy-subrc = 0 AND es_col_id-fieldname = 'ACTION'.
      ADD 1 TO <row>-quantity.
      go_grid->refresh_table_display(
        is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
      gv_status = |Button cell raised quantity for { <row>-id } to { <row>-quantity }|.
    ENDIF.
  ENDMETHOD.

  METHOD on_f4.
    DATA lt_values TYPE ty_f4_values.
    DATA lt_return TYPE STANDARD TABLE OF ddshretval WITH EMPTY KEY.

    IF e_fieldname <> 'NAME'.
      RETURN.
    ENDIF.
    lt_values = VALUE #( ( 'Keyboard from custom F4' )
      ( 'Display from custom F4' ) ( 'Dock from custom F4' ) ).
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING retfield = 'FIELDVAL' value_org = 'S'
      TABLES value_tab = lt_values return_tab = lt_return
      EXCEPTIONS parameter_error = 1 no_values_found = 2 OTHERS = 3.
    IF sy-subrc = 0 AND lt_return IS NOT INITIAL AND go_protocol IS BOUND.
      READ TABLE lt_return INDEX 1 INTO DATA(ls_return).
      go_protocol->modify_cell(
        i_row_id    = es_row_no-row_id
        i_fieldname = e_fieldname
        i_value     = ls_return-fieldval ).
    ENDIF.
    er_event_data->m_event_handled = abap_true.
    gv_status = |Custom F4 handled row { es_row_no-row_id }; previous value { e_fieldvalue }, display flag { e_display }|.
    gv_detail = |Bad-cell context contained { lines( et_bad_cells ) } entries|.
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
    WHEN 'CHECK'.
      PERFORM check_edits.
    WHEN 'PROTOCOL'.
      PERFORM display_protocol.
    WHEN 'INSERT'.
      PERFORM insert_row.
    WHEN 'COPY'.
      PERFORM copy_row.
    WHEN 'DELETE'.
      PERFORM delete_rows.
    WHEN 'SAVE'.
      PERFORM save_changes.
    WHEN 'DISCARD'.
      PERFORM discard_changes.
    WHEN 'RESET'.
      PERFORM reset_rows.
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
  TRY.
      CREATE OBJECT go_grid EXPORTING i_parent      = go_host
                                      i_appl_events = abap_true.
      CREATE OBJECT go_events.
      SET HANDLER go_events->on_data_changed FOR go_grid.
      SET HANDLER go_events->on_data_changed_finished FOR go_grid.
      SET HANDLER go_events->on_button_click FOR go_grid.
      SET HANDLER go_events->on_f4 FOR go_grid.
      go_grid->register_edit_event( cl_gui_alv_grid=>mc_evt_enter ).
      go_grid->register_edit_event( cl_gui_alv_grid=>mc_evt_modified ).
      go_grid->register_f4_for_fields( VALUE lvc_t_f4(
        ( fieldname = 'NAME' register = abap_true getbefore = abap_true chngeafter = abap_true ) ) ).
      go_grid->set_drop_down_table( it_drop_down = VALUE lvc_t_drop(
        ( handle = 1 value = 'Standard' )
        ( handle = 1 value = 'Priority' )
        ( handle = 1 value = 'Deferred' ) ) ).
      go_grid->set_table_for_first_display(
        EXPORTING is_layout = VALUE lvc_s_layo(
          zebra = abap_true cwidth_opt = abap_true edit = abap_true
          stylefname = 'STYLES' grid_title = 'Editable ALV Grid - in-memory only' )
        CHANGING it_outtab = gt_rows it_fieldcatalog = gt_fieldcat ).
      go_grid->set_ready_for_input( 1 ).
      gv_status = 'Editable ALV created with checkbox, dropdown, button, hotspot, F4, validation, and edit events'.
      gv_detail = 'Save and Discard affect only the report snapshot; this sample never updates a database table'.
    CATCH cx_root INTO DATA(lx_error).
      FREE: go_grid, go_events.
      PERFORM show_fallback USING lx_error.
  ENDTRY.
ENDFORM.

FORM build_rows.
  DATA lt_products TYPE zcl_gg_gui_demo_data=>ty_products.

  CLEAR gt_rows.
  lt_products = zcl_gg_gui_demo_data=>products( ).
  LOOP AT lt_products INTO DATA(ls_product).
    DATA(ls_row) = VALUE ty_row(
      id = ls_product-id name = ls_product-name category = ls_product-category
      quantity = ls_product-quantity price = ls_product-price
      currency = ls_product-currency active = ls_product-active
      choice = 'Standard' action = 'Add one' ).
    APPEND VALUE #( fieldname = 'ACTION' style = cl_gui_alv_grid=>mc_style_button ) TO ls_row-styles.
    IF ls_product-active = abap_false.
      APPEND VALUE #( fieldname = 'QUANTITY' style = cl_gui_alv_grid=>mc_style_disabled ) TO ls_row-styles.
    ENDIF.
    APPEND ls_row TO gt_rows.
  ENDLOOP.
  gt_saved_rows = gt_rows.
ENDFORM.

FORM build_field_catalog.
  gt_fieldcat = VALUE #(
    ( fieldname = 'ID' col_pos = 1 coltext = 'Product ID' key = abap_true hotspot = abap_true outputlen = 10 )
    ( fieldname = 'NAME' col_pos = 2 coltext = 'Editable name' edit = abap_true f4availabl = abap_true outputlen = 28 )
    ( fieldname = 'CATEGORY' col_pos = 3 coltext = 'Category' outputlen = 18 )
    ( fieldname = 'QUANTITY' col_pos = 4 coltext = 'Quantity' edit = abap_true outputlen = 10 )
    ( fieldname = 'PRICE' col_pos = 5 coltext = 'Price' edit = abap_true cfieldname = 'CURRENCY'
      decimals_o = 2 outputlen = 14 )
    ( fieldname = 'CURRENCY' col_pos = 6 coltext = 'Currency' outputlen = 8 )
    ( fieldname = 'ACTIVE' col_pos = 7 coltext = 'Active' edit = abap_true checkbox = abap_true outputlen = 7 )
    ( fieldname = 'CHOICE' col_pos = 8 coltext = 'Dropdown' edit = abap_true drdn_hndl = 1 outputlen = 12 )
    ( fieldname = 'ACTION' col_pos = 9 coltext = 'Button' outputlen = 12 ) ).
ENDFORM.

FORM check_edits.
  DATA lv_valid TYPE abap_bool.
  DATA lv_refresh TYPE abap_bool VALUE abap_true.

  IF go_grid IS NOT BOUND.
    gv_status = 'Editable ALV is unavailable; changes cannot be checked'.
    RETURN.
  ENDIF.
  TRY.
      go_grid->check_changed_data(
        IMPORTING e_valid = lv_valid CHANGING c_refresh = lv_refresh ).
      gv_status = |CHECK_CHANGED_DATA completed; valid { lv_valid }, refreshed { lv_refresh }|.
      gv_detail = COND #( WHEN gt_rows = gt_saved_rows
        THEN 'No unsaved in-memory changes detected' ELSE 'Unsaved in-memory changes detected' ).
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Edit check failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM display_protocol.
  IF go_protocol IS NOT BOUND.
    gv_status = 'Trigger a validation event before displaying the changed-data protocol'.
    RETURN.
  ENDIF.
  TRY.
      go_protocol->refresh_protocol( ).
      go_protocol->display_protocol(
        i_display_toolbar  = abap_true
        i_optimize_columns = abap_true ).
      gv_status = |Protocol displayed with { lines( go_protocol->mt_protocol ) } entries|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Protocol display failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM insert_row.
  ADD 1 TO gv_next_id.
  INSERT VALUE #(
    id = |P{ gv_next_id }| name = 'Inserted product' category = 'Runtime'
    quantity = 1 price = '10.00' currency = 'EUR' active = abap_true
    choice = 'Standard' action = 'Add one'
    styles = VALUE #( ( fieldname = 'ACTION' style = cl_gui_alv_grid=>mc_style_button ) ) )
    INTO gt_rows INDEX 1.
  PERFORM refresh_grid.
  gv_status = 'A new editable row was inserted at index 1; it remains in memory until Save'.
ENDFORM.

FORM copy_row.
  READ TABLE gt_rows INDEX 1 INTO DATA(ls_row).
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.
  ADD 1 TO gv_next_id.
  ls_row-id = |P{ gv_next_id }|.
  ls_row-name = |Copy of { ls_row-name }|.
  APPEND ls_row TO gt_rows.
  PERFORM refresh_grid.
  gv_status = |Row 1 copied to index { lines( gt_rows ) } with ID { ls_row-id }|.
ENDFORM.

FORM delete_rows.
  DATA lt_selected TYPE lvc_t_row.

  IF go_grid IS NOT BOUND.
    RETURN.
  ENDIF.
  TRY.
      go_grid->get_selected_rows( IMPORTING et_index_rows = lt_selected ).
      SORT lt_selected BY index DESCENDING.
      LOOP AT lt_selected INTO DATA(ls_selected).
        DELETE gt_rows INDEX ls_selected-index.
      ENDLOOP.
      PERFORM refresh_grid.
      gv_status = |Deleted { lines( lt_selected ) } selected rows from the in-memory working table|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Row deletion failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM save_changes.
  PERFORM check_edits.
  gt_saved_rows = gt_rows.
  gv_status = |Saved { lines( gt_saved_rows ) } rows to the report snapshot only|.
  gv_detail = 'No database update, commit, or productive table access occurs'.
ENDFORM.

FORM discard_changes.
  gt_rows = gt_saved_rows.
  PERFORM refresh_grid.
  gv_status = 'Discarded unsaved edits and restored the last in-memory snapshot'.
ENDFORM.

FORM reset_rows.
  gv_next_id = 500.
  PERFORM build_rows.
  PERFORM refresh_grid.
  CLEAR go_protocol.
  gv_status = 'Rows, cell styles, dropdown values, and the saved snapshot reset to deterministic values'.
ENDFORM.

FORM refresh_grid.
  IF go_grid IS BOUND.
    TRY.
        go_grid->refresh_table_display(
          is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
      CATCH cx_root INTO DATA(lx_error).
        gv_detail = |Grid refresh failed: { lx_error->get_text( ) }|.
    ENDTRY.
  ENDIF.
ENDFORM.

FORM show_fallback USING io_error TYPE REF TO cx_root.
  DATA lt_text TYPE ty_text_lines.

  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( 'Editable CL_GUI_ALV_GRID behavior is unavailable in this runtime.' )
    ( 'The native SAP report keeps edit events and CL_ALV_CHANGED_DATA_PROTOCOL calls syntax checked.' )
    ( 'Save and discard are deliberately limited to an in-memory snapshot.' ) ).
  go_fallback->set_text_as_r3table( lt_text ).
  go_fallback->set_readonly_mode( 1 ).
  gv_status = 'Editable ALV unavailable; a non-terminating text fallback is displayed'.
  gv_detail = io_error->get_text( ).
ENDFORM.

FORM free_controls.
  FREE: go_protocol, go_events.
  IF go_grid IS BOUND. go_grid->free( ). FREE go_grid. ENDIF.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
