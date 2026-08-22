REPORT zgg_gui_alv_variants.

TYPES ty_rows TYPE zcl_gg_gui_demo_data=>ty_products.
TYPES ty_variants TYPE STANDARD TABLE OF disvariant WITH EMPTY KEY.
TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

DATA gt_rows TYPE ty_rows.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA gt_owned_variants TYPE ty_variants.
DATA gs_layout TYPE lvc_s_layo.
DATA gs_variant TYPE disvariant.
DATA gr_rows TYPE REF TO data.
DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA go_variant TYPE REF TO cl_alv_variant.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_variant_name TYPE c LENGTH 12 VALUE 'GG_DEMO'.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_switch_index TYPE i.

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
    WHEN 'INFO'.
      PERFORM read_variant_info.
    WHEN 'APPLY'.
      PERFORM apply_variant.
    WHEN 'SAVE'.
      PERFORM save_variant.
    WHEN 'SWITCH'.
      PERFORM switch_variant.
    WHEN 'DELETE'.
      PERFORM delete_current_variant.
    WHEN 'CLEANUP'.
      PERFORM cleanup_owned_variants.
    WHEN 'RESET'.
      PERFORM reset_layout.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  IF go_grid IS BOUND OR go_fallback IS BOUND.
    RETURN.
  ENDIF.

  gt_rows = zcl_gg_gui_demo_data=>products( ).
  PERFORM build_field_catalog.
  gs_layout = VALUE #(
    zebra = abap_true cwidth_opt = abap_true sel_mode = 'A'
    grid_title = 'Direct ALV variant handling' ).
  gs_variant = VALUE #(
    report = sy-repid handle = 'GGV1' username = sy-uname variant = gv_variant_name ).
  GET REFERENCE OF gt_rows INTO gr_rows.

  TRY.
      CREATE OBJECT go_variant
        EXPORTING it_outtab       = gr_rows
                  it_fieldcatalog = gt_fieldcat
          is_variant              = gs_variant
                  is_layout       = gs_layout.
      CREATE OBJECT go_grid EXPORTING i_parent = go_host.
      go_grid->set_table_for_first_display(
        EXPORTING is_variant = gs_variant
                  i_save = 'A'
                  i_default = abap_false
          is_layout = gs_layout
        CHANGING it_outtab = gt_rows it_fieldcatalog = gt_fieldcat ).
      gv_status = 'CL_ALV_VARIANT and its owning ALV Grid were created for report-local handle GGV1'.
      gv_detail = 'Only variants explicitly saved by this run and prefixed GG_ are eligible for deletion'.
    CATCH cx_root INTO DATA(lx_error).
      FREE: go_grid, go_variant.
      PERFORM show_fallback USING lx_error.
  ENDTRY.
ENDFORM.

FORM build_field_catalog.
  gt_fieldcat = VALUE #(
    ( fieldname = 'ID' col_pos = 1 coltext = 'Product ID' key = abap_true outputlen = 10 )
    ( fieldname = 'NAME' col_pos = 2 coltext = 'Product name' outputlen = 30 )
    ( fieldname = 'CATEGORY' col_pos = 3 coltext = 'Category' outputlen = 20 )
    ( fieldname = 'QUANTITY' col_pos = 4 coltext = 'Quantity' do_sum = abap_true outputlen = 10 )
    ( fieldname = 'PRICE' col_pos = 5 coltext = 'Price' cfieldname = 'CURRENCY'
      do_sum = abap_true outputlen = 14 decimals_o = 2 )
    ( fieldname = 'CURRENCY' col_pos = 6 coltext = 'Currency' outputlen = 8 ) ).
ENDFORM.

FORM validate_name CHANGING cv_valid TYPE abap_bool.
  cv_valid = abap_false.
  TRANSLATE gv_variant_name TO UPPER CASE.
  IF gv_variant_name NP 'GG_*' OR strlen( gv_variant_name ) < 4.
    gv_status = 'Use a sample-owned variant name beginning with GG_'.
    gv_detail = 'The prefix and report-local GGV1 handle prevent deletion of unrelated variants'.
    RETURN.
  ENDIF.
  cv_valid = abap_true.
ENDFORM.

FORM current_key CHANGING cs_variant TYPE disvariant.
  cs_variant = VALUE #(
    report = sy-repid handle = 'GGV1' username = sy-uname variant = gv_variant_name ).
ENDFORM.

FORM read_variant_info.
  DATA ls_key TYPE disvariant.
  DATA lt_stored_catalog TYPE lvc_t_fcat.
  DATA lv_valid TYPE abap_bool.

  PERFORM validate_name CHANGING lv_valid.
  IF lv_valid = abap_false OR go_variant IS NOT BOUND.
    RETURN.
  ENDIF.
  PERFORM current_key CHANGING ls_key.
  TRY.
      go_variant->get_variant_info_from_db(
        EXPORTING is_variant  = ls_key
                  it_def_fcat = gt_fieldcat
        IMPORTING et_fcat     = lt_stored_catalog ).
      gv_status = |Variant { gv_variant_name } returned { lines( lt_stored_catalog ) } stored field-catalog entries|.
      gv_detail = |Default catalog fallback contains { lines( gt_fieldcat ) } entries|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Variant information could not be read: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM apply_variant.
  DATA ls_key TYPE disvariant.
  DATA lv_valid TYPE abap_bool.

  PERFORM validate_name CHANGING lv_valid.
  IF lv_valid = abap_false OR go_grid IS NOT BOUND.
    RETURN.
  ENDIF.
  PERFORM current_key CHANGING ls_key.
  TRY.
      go_grid->set_variant( is_variant = ls_key
                            i_save     = 'A' ).
      go_grid->refresh_table_display(
        is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
      gv_status = |Variant { gv_variant_name } applied to the current grid|.
      gv_detail = |Key: report { sy-repid }, handle GGV1, user { sy-uname }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Variant apply failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM save_variant.
  DATA ls_key TYPE disvariant.
  DATA lv_valid TYPE abap_bool.
  DATA lv_exit TYPE abap_bool.

  PERFORM validate_name CHANGING lv_valid.
  IF lv_valid = abap_false OR go_grid IS NOT BOUND.
    RETURN.
  ENDIF.
  PERFORM current_key CHANGING ls_key.
  TRY.
      go_grid->set_variant( is_variant = ls_key
                            i_save     = 'A' ).
      go_grid->save_variant( EXPORTING i_dialog = abap_false IMPORTING e_exit = lv_exit ).
      IF lv_exit = abap_false.
        READ TABLE gt_owned_variants WITH KEY variant = ls_key-variant TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          APPEND ls_key TO gt_owned_variants.
        ENDIF.
        gv_status = |Sample-owned variant { gv_variant_name } saved; tracked variants: { lines( gt_owned_variants ) }|.
      ELSE.
        gv_status = |Save of variant { gv_variant_name } was canceled|.
      ENDIF.
      gv_detail = 'The run records the exact keys it may later delete; it does not scan the user variant catalog'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Variant save failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM switch_variant.
  IF gt_owned_variants IS INITIAL.
    gv_status = 'Save at least one GG_ variant before using Switch'.
    RETURN.
  ENDIF.
  ADD 1 TO gv_switch_index.
  IF gv_switch_index > lines( gt_owned_variants ).
    gv_switch_index = 1.
  ENDIF.
  READ TABLE gt_owned_variants INDEX gv_switch_index INTO DATA(ls_key).
  gv_variant_name = ls_key-variant.
  PERFORM apply_variant.
  gv_detail = |Switched to tracked sample variant { gv_switch_index } of { lines( gt_owned_variants ) }|.
ENDFORM.

FORM delete_current_variant.
  DATA lt_delete TYPE ty_variants.
  DATA ls_key TYPE disvariant.
  DATA lv_answer TYPE c LENGTH 1.
  DATA lv_deleted TYPE abap_bool.

  PERFORM current_key CHANGING ls_key.
  READ TABLE gt_owned_variants WITH KEY variant = ls_key-variant TRANSPORTING NO FIELDS.
  IF sy-subrc <> 0.
    gv_status = |Variant { gv_variant_name } was not created and tracked by this run; deletion refused|.
    RETURN.
  ENDIF.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING titlebar = 'Delete sample ALV variant'
      text_question = |Delete { gv_variant_name } for handle GGV1?|
      text_button_1 = 'Delete' text_button_2 = 'Keep' default_button = '2'
    IMPORTING answer = lv_answer.
  IF lv_answer <> '1'.
    gv_status = 'Variant deletion canceled'.
    RETURN.
  ENDIF.
  APPEND ls_key TO lt_delete.
  TRY.
      CALL METHOD go_variant->('DELETE_VARIANTS')
        EXPORTING it_variants = lt_delete
        RECEIVING boolean = lv_deleted.
      IF lv_deleted = abap_true.
        DELETE gt_owned_variants WHERE variant = ls_key-variant.
      ENDIF.
      gv_status = |Delete result for { gv_variant_name }: { lv_deleted }|.
      gv_detail = |Tracked sample variants remaining: { lines( gt_owned_variants ) }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Variant deletion failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM cleanup_owned_variants.
  DATA lv_answer TYPE c LENGTH 1.
  DATA lv_deleted TYPE abap_bool.

  IF gt_owned_variants IS INITIAL.
    gv_status = 'No variants created by this run are tracked for cleanup'.
    RETURN.
  ENDIF.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING titlebar = 'Clean up sample ALV variants'
      text_question = |Delete all { lines( gt_owned_variants ) } tracked GG_ variants?|
      text_button_1 = 'Delete' text_button_2 = 'Keep' default_button = '2'
    IMPORTING answer = lv_answer.
  IF lv_answer <> '1'.
    gv_status = 'Variant cleanup canceled'.
    RETURN.
  ENDIF.
  TRY.
      CALL METHOD go_variant->('DELETE_VARIANTS')
        EXPORTING it_variants = gt_owned_variants
        RECEIVING boolean = lv_deleted.
      IF lv_deleted = abap_true.
        CLEAR gt_owned_variants.
      ENDIF.
      gv_status = |Sample-owned variant cleanup result: { lv_deleted }|.
      gv_detail = 'Only keys recorded after successful sample saves were supplied to DELETE_VARIANTS'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Variant cleanup failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM reset_layout.
  CLEAR: gt_owned_variants, gv_switch_index.
  gv_variant_name = 'GG_DEMO'.
  IF go_grid IS BOUND.
    TRY.
        go_grid->set_frontend_fieldcatalog( gt_fieldcat ).
        go_grid->set_frontend_layout( gs_layout ).
        go_grid->refresh_table_display(
          is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
        gv_status = 'Frontend layout and in-memory ownership tracking reset; stored variants were not deleted'.
      CATCH cx_root INTO DATA(lx_error).
        gv_status = |Variant sample reset failed: { lx_error->get_text( ) }|.
    ENDTRY.
  ENDIF.
ENDFORM.

FORM show_fallback USING io_error TYPE REF TO cx_root.
  DATA lt_text TYPE ty_text_lines.

  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( 'The ALV variant sample cannot display its owning grid in this runtime.' )
    ( 'CL_ALV_VARIANT is declared, but its methods do not persist or retrieve state in open-abap.' )
    ( 'The native SAP code remains syntax checked and all deletion is constrained to tracked GG_ keys.' ) ).
  go_fallback->set_text_as_r3table( lt_text ).
  go_fallback->set_readonly_mode( 1 ).
  gv_status = 'ALV variants unavailable; a non-terminating text fallback is displayed'.
  gv_detail = io_error->get_text( ).
ENDFORM.

FORM free_controls.
  IF go_grid IS BOUND. go_grid->free( ). FREE go_grid. ENDIF.
  FREE go_variant.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
