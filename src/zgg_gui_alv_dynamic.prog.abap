REPORT zgg_gui_alv_dynamic.

TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.
TYPES ty_price TYPE p LENGTH 8 DECIMALS 2.

CONSTANTS c_price_129 TYPE ty_price VALUE '129.90'.
CONSTANTS c_price_389 TYPE ty_price VALUE '389.00'.
CONSTANTS c_price_219 TYPE ty_price VALUE '219.00'.
CONSTANTS c_price_42 TYPE ty_price VALUE '42.00'.

DATA gt_fieldcat TYPE lvc_t_fcat.
DATA gr_table TYPE REF TO data.
DATA gv_style_field TYPE lvc_fname.
DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_sequence TYPE i.

FIELD-SYMBOLS <gt_output> TYPE ANY TABLE.

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
    WHEN 'APPEND'.
      PERFORM append_runtime_row.
    WHEN 'STYLE'.
      PERFORM change_runtime_style.
    WHEN 'DESCRIBE'.
      PERFORM describe_runtime_table.
    WHEN 'REFRESH'.
      PERFORM refresh_grid.
    WHEN 'RESET'.
      PERFORM reset_rows.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  DATA lv_error_text TYPE string.

  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  IF go_grid IS BOUND OR go_fallback IS BOUND.
    RETURN.
  ENDIF.

  PERFORM build_field_catalog.
  TRY.
      cl_alv_table_create=>create_dynamic_table(
        EXPORTING it_fieldcatalog = gt_fieldcat
                  i_style_table = abap_true
          i_length_in_byte = abap_true
        IMPORTING ep_table = gr_table e_style_fname = gv_style_field ).
      IF gr_table IS NOT BOUND.
        PERFORM show_fallback USING 'CREATE_DYNAMIC_TABLE returned an unbound table reference'.
        RETURN.
      ENDIF.
      ASSIGN gr_table->* TO <gt_output>.
      PERFORM populate_initial_rows.

      CREATE OBJECT go_grid EXPORTING i_parent = go_host.
      DATA(ls_layout) = VALUE lvc_s_layo(
        zebra = abap_true cwidth_opt = abap_true sel_mode = 'A'
        stylefname = gv_style_field grid_title = 'Runtime-created ALV output table' ).
      go_grid->set_table_for_first_display(
        EXPORTING is_layout = ls_layout
        CHANGING it_outtab = <gt_output> it_fieldcatalog = gt_fieldcat ).
      gv_status = |Dynamic table created with { lines( gt_fieldcat ) } catalog fields and displayed in CL_GUI_ALV_GRID|.
      gv_detail = |Generated style component: { gv_style_field }; rows: { lines( <gt_output> ) }|.
    CATCH cx_root INTO DATA(lx_error).
      FREE: go_grid, gr_table.
      UNASSIGN <gt_output>.
      lv_error_text = lx_error->get_text( ).
      PERFORM show_fallback USING lv_error_text.
  ENDTRY.
ENDFORM.

FORM build_field_catalog.
  gt_fieldcat = VALUE #(
    ( fieldname = 'ID' col_pos = 1 coltext = 'Runtime ID' key = abap_true
      datatype = 'CHAR' inttype = 'C' intlen = 8 outputlen = 8 )
    ( fieldname = 'NAME' col_pos = 2 coltext = 'Generated name'
      datatype = 'CHAR' inttype = 'C' intlen = 30 outputlen = 30 )
    ( fieldname = 'QUANTITY' col_pos = 3 coltext = 'Quantity' do_sum = abap_true
      datatype = 'INT4' inttype = 'I' intlen = 4 outputlen = 10 )
    ( fieldname = 'PRICE' col_pos = 4 coltext = 'Price' do_sum = abap_true
      datatype = 'DEC' inttype = 'P' intlen = 8 decimals = 2 decimals_o = 2
      outputlen = 14 cfieldname = 'CURRENCY' )
    ( fieldname = 'CURRENCY' col_pos = 5 coltext = 'Currency'
      datatype = 'CUKY' inttype = 'C' intlen = 3 outputlen = 5 )
    ( fieldname = 'ACTIVE' col_pos = 6 coltext = 'Active' checkbox = abap_true edit = abap_true
      datatype = 'CHAR' inttype = 'C' intlen = 1 outputlen = 6 ) ).
ENDFORM.

FORM populate_initial_rows.
  PERFORM append_row USING 'D100' 'Runtime keyboard' 12 c_price_129 'EUR' abap_true.
  PERFORM append_row USING 'D200' 'Runtime display' 4 c_price_389 'EUR' abap_true.
  PERFORM append_row USING 'D300' 'Runtime dock' 0 c_price_219 'EUR' abap_false.
  gv_sequence = 3.
ENDFORM.

FORM append_row USING iv_id TYPE c iv_name TYPE c iv_quantity TYPE i
    iv_price TYPE ty_price iv_currency TYPE c iv_active TYPE abap_bool.
  FIELD-SYMBOLS <ls_row> TYPE any.
  FIELD-SYMBOLS <lv_component> TYPE any.

  APPEND INITIAL LINE TO <gt_output> ASSIGNING <ls_row>.
  ASSIGN COMPONENT 'ID' OF STRUCTURE <ls_row> TO <lv_component>.
  <lv_component> = iv_id.
  ASSIGN COMPONENT 'NAME' OF STRUCTURE <ls_row> TO <lv_component>.
  <lv_component> = iv_name.
  ASSIGN COMPONENT 'QUANTITY' OF STRUCTURE <ls_row> TO <lv_component>.
  <lv_component> = iv_quantity.
  ASSIGN COMPONENT 'PRICE' OF STRUCTURE <ls_row> TO <lv_component>.
  <lv_component> = iv_price.
  ASSIGN COMPONENT 'CURRENCY' OF STRUCTURE <ls_row> TO <lv_component>.
  <lv_component> = iv_currency.
  ASSIGN COMPONENT 'ACTIVE' OF STRUCTURE <ls_row> TO <lv_component>.
  <lv_component> = iv_active.
  PERFORM set_style_for_row USING <ls_row>.
ENDFORM.

FORM set_style_for_row USING is_row TYPE any.
  FIELD-SYMBOLS <lt_styles> TYPE ANY TABLE.
  FIELD-SYMBOLS <ls_style> TYPE any.
  FIELD-SYMBOLS <lv_component> TYPE any.

  IF gv_style_field IS INITIAL.
    RETURN.
  ENDIF.
  ASSIGN COMPONENT gv_style_field OF STRUCTURE is_row TO <lt_styles>.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.
  APPEND INITIAL LINE TO <lt_styles> ASSIGNING <ls_style>.
  ASSIGN COMPONENT 'FIELDNAME' OF STRUCTURE <ls_style> TO <lv_component>.
  IF sy-subrc = 0. <lv_component> = 'ACTIVE'. ENDIF.
  ASSIGN COMPONENT 'STYLE' OF STRUCTURE <ls_style> TO <lv_component>.
  IF sy-subrc = 0. <lv_component> = cl_gui_alv_grid=>mc_style_enabled. ENDIF.
ENDFORM.

FORM append_runtime_row.
  IF <gt_output> IS NOT ASSIGNED.
    gv_status = 'Dynamic table is unavailable; no runtime row can be appended'.
    RETURN.
  ENDIF.
  ADD 1 TO gv_sequence.
  DATA lv_id TYPE c LENGTH 8.

  lv_id = |D{ gv_sequence WIDTH = 3 PAD = '0' }|.
  PERFORM append_row USING lv_id 'Appended through field symbols'
    gv_sequence c_price_42 'EUR' abap_true.
  PERFORM refresh_grid.
  gv_status = |Generic field-symbol population appended row { lv_id }|.
ENDFORM.

FORM change_runtime_style.
  FIELD-SYMBOLS <ls_row> TYPE any.
  FIELD-SYMBOLS <lt_styles> TYPE ANY TABLE.
  FIELD-SYMBOLS <ls_style> TYPE any.
  FIELD-SYMBOLS <lv_style> TYPE any.

  IF <gt_output> IS NOT ASSIGNED OR gv_style_field IS INITIAL.
    gv_status = 'Generated style component is unavailable'.
    RETURN.
  ENDIF.
  READ TABLE <gt_output> INDEX 1 ASSIGNING <ls_row>.
  ASSIGN COMPONENT gv_style_field OF STRUCTURE <ls_row> TO <lt_styles>.
  READ TABLE <lt_styles> INDEX 1 ASSIGNING <ls_style>.
  ASSIGN COMPONENT 'STYLE' OF STRUCTURE <ls_style> TO <lv_style>.
  IF sy-subrc = 0.
    <lv_style> = COND #( WHEN <lv_style> = cl_gui_alv_grid=>mc_style_disabled
      THEN cl_gui_alv_grid=>mc_style_enabled ELSE cl_gui_alv_grid=>mc_style_disabled ).
    PERFORM refresh_grid.
    gv_status = 'The generated style table toggled the ACTIVE cell in row 1 between enabled and disabled'.
  ENDIF.
ENDFORM.

FORM describe_runtime_table.
  DATA lo_table TYPE REF TO cl_abap_tabledescr.
  DATA lo_line TYPE REF TO cl_abap_structdescr.
  DATA lt_components TYPE abap_component_tab.

  IF gr_table IS NOT BOUND.
    gv_status = 'Dynamic table is unavailable; RTTI metadata cannot be read'.
    RETURN.
  ENDIF.
  TRY.
      lo_table ?= cl_abap_tabledescr=>describe_by_data_ref( gr_table ).
      lo_line ?= lo_table->get_table_line_type( ).
      lt_components = lo_line->get_components( ).
      gv_status = |RTTI reports { lines( lt_components ) } row components and { lines( <gt_output> ) } rows|.
      gv_detail = |Style field { gv_style_field }; factory reference bound: { xsdbool( gr_table IS BOUND ) }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Dynamic table description failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM refresh_grid.
  IF go_grid IS NOT BOUND.
    RETURN.
  ENDIF.
  TRY.
      go_grid->refresh_table_display(
        is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
      gv_detail = |Dynamic ALV refreshed with { lines( <gt_output> ) } rows|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Dynamic ALV refresh failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM reset_rows.
  IF <gt_output> IS NOT ASSIGNED.
    gv_status = 'Dynamic table is unavailable; the fallback remains visible'.
    RETURN.
  ENDIF.
  CLEAR <gt_output>.
  PERFORM populate_initial_rows.
  PERFORM refresh_grid.
  gv_status = 'Dynamic rows and generated cell-style entries reset to deterministic values'.
ENDFORM.

FORM show_fallback USING iv_error TYPE string.
  DATA lt_text TYPE ty_text_lines.

  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( 'CL_ALV_TABLE_CREATE is unavailable or nonfunctional in this runtime.' )
    ( 'The native SAP sample keeps the static factory and generic population code syntax checked.' )
    ( 'The pinned open-abap-gui implementation currently terminates with an assertion.' ) ).
  go_fallback->set_text_as_r3table( lt_text ).
  go_fallback->set_readonly_mode( 1 ).
  gv_status = 'Dynamic ALV table unavailable; a non-terminating text fallback is displayed'.
  gv_detail = iv_error.
ENDFORM.

FORM free_controls.
  IF go_grid IS BOUND. go_grid->free( ). FREE go_grid. ENDIF.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
  UNASSIGN <gt_output>.
  FREE gr_table.
ENDFORM.
