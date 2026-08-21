REPORT zgg_gui_office_integration.

TYPES:
  BEGIN OF ty_oi_field,
    field_name     TYPE c LENGTH 40,
    field_text     TYPE c LENGTH 40,
    field_type     TYPE c LENGTH 1,
    field_length   TYPE i,
    field_decimals TYPE i,
  END OF ty_oi_field,
  ty_oi_fields TYPE STANDARD TABLE OF ty_oi_field WITH EMPTY KEY.
TYPES:
  BEGIN OF ty_oi_cell,
    row    TYPE i,
    column TYPE i,
    value  TYPE c LENGTH 255,
  END OF ty_oi_cell,
  ty_oi_cells TYPE STANDARD TABLE OF ty_oi_cell WITH EMPTY KEY.
TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_office TYPE REF TO object.
DATA go_document TYPE REF TO object.
DATA go_sheet TYPE REF TO object.
DATA go_word TYPE REF TO object.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108 VALUE 'SAP GUI for Windows and locally installed Office application required'.
DATA gv_available TYPE abap_bool.
DATA gv_document_kind TYPE c LENGTH 12.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_office_host.
ENDMODULE.

MODULE exit_0100 INPUT.
  PERFORM release_office.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.
  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_ok_code.
    WHEN 'SHEET'.
      PERFORM show_spreadsheet.
    WHEN 'WORD'.
      PERFORM show_word_document.
    WHEN 'CLOSE'.
      PERFORM close_document.
    WHEN 'AUDIT'.
      PERFORM audit_office.
    WHEN 'RESET'.
      PERFORM release_office.
      PERFORM create_office_host.
  ENDCASE.
ENDMODULE.

FORM create_office_host.
  DATA lv_creator TYPE string VALUE 'C_OI_CONTAINER_CONTROL_CREATOR'.
  DATA lv_factory TYPE string VALUE 'GET_CONTAINER_CONTROL'.
  DATA lv_retcode TYPE i.
  DATA lv_reason TYPE string.

  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  IF go_office IS BOUND OR go_fallback IS BOUND.
    RETURN.
  ENDIF.
  PERFORM detect_office.
  IF gv_available = abap_false.
    PERFORM show_fallback USING 'C_OI_CONTAINER_CONTROL_CREATOR is not installed in this runtime'.
    RETURN.
  ENDIF.
  TRY.
      CALL METHOD (lv_creator)=>(lv_factory)
        IMPORTING control = go_office retcode = lv_retcode.
      IF go_office IS NOT BOUND OR lv_retcode <> 0.
        lv_reason = |Office container creator returned code { lv_retcode } and no usable control|.
        PERFORM show_fallback USING lv_reason.
        RETURN.
      ENDIF.
      CALL METHOD go_office->('INIT_CONTROL')
        EXPORTING r3_application_name = 'GG GUI Office sample'
          parent = go_host inplace_enabled = abap_true no_flush = abap_false
        IMPORTING retcode = lv_retcode.
      IF lv_retcode <> 0.
        lv_reason = |Desktop Office initialization returned code { lv_retcode }|.
        PERFORM show_fallback USING lv_reason.
        RETURN.
      ENDIF.
      gv_status = 'Desktop Office container initialized in-place; choose Spreadsheet or Word sample'.
      gv_detail = 'SAP GUI for Windows and locally installed Office application required'.
    CATCH cx_root INTO DATA(lx_error).
      lv_reason = lx_error->get_text( ).
      PERFORM show_fallback USING lv_reason.
  ENDTRY.
ENDFORM.

FORM detect_office.
  DATA lo_descr TYPE REF TO cl_abap_typedescr.

  gv_available = abap_false.
  TRY.
      lo_descr = cl_abap_classdescr=>describe_by_name( 'C_OI_CONTAINER_CONTROL_CREATOR' ).
      gv_available = xsdbool( lo_descr IS BOUND ).
    CATCH cx_root.
      gv_available = abap_false.
  ENDTRY.
ENDFORM.

FORM get_document USING iv_type TYPE string iv_title TYPE string.
  DATA lv_retcode TYPE i.

  PERFORM close_document.
  IF go_office IS NOT BOUND.
    gv_status = 'Desktop Office container is unavailable'.
    RETURN.
  ENDIF.
  TRY.
      CALL METHOD go_office->('GET_DOCUMENT_PROXY')
        EXPORTING document_type = iv_type document_format = 'OLE'
          register_container = abap_true no_flush = abap_false
        IMPORTING document_proxy = go_document retcode = lv_retcode.
      IF go_document IS NOT BOUND OR lv_retcode <> 0.
        gv_status = |No { iv_type } document proxy; return code { lv_retcode }|.
        RETURN.
      ENDIF.
      CALL METHOD go_document->('CREATE_DOCUMENT')
        EXPORTING document_title = iv_title open_inplace = abap_true
          create_view_data = abap_false no_flush = abap_false
        IMPORTING retcode = lv_retcode.
      IF lv_retcode <> 0.
        gv_status = |{ iv_type } could not create an embedded document; return code { lv_retcode }|.
        RETURN.
      ENDIF.
      gv_document_kind = iv_type.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Document creation failed: { lx_error->get_text( ) }|.
      FREE go_document.
  ENDTRY.
ENDFORM.

FORM show_spreadsheet.
  DATA lt_fields TYPE ty_oi_fields.
  DATA lt_cells TYPE ty_oi_cells.
  DATA lv_retcode TYPE i.

  PERFORM get_document USING 'Excel.Sheet' 'GG GUI deterministic spreadsheet'.
  IF go_document IS NOT BOUND. RETURN. ENDIF.
  lt_fields = VALUE #(
    ( field_name = 'ID' field_text = 'ID' field_type = 'C' field_length = 8 )
    ( field_name = 'PRODUCT' field_text = 'Product' field_type = 'C' field_length = 30 )
    ( field_name = 'QUANTITY' field_text = 'Quantity' field_type = 'N' field_length = 8 ) ).
  lt_cells = VALUE #(
    ( row = 1 column = 1 value = 'P100' )
    ( row = 1 column = 2 value = 'Mechanical Keyboard' )
    ( row = 1 column = 3 value = '12' )
    ( row = 2 column = 1 value = 'P110' )
    ( row = 2 column = 2 value = 'Ergonomic Mouse' )
    ( row = 2 column = 3 value = '7' )
    ( row = 3 column = 1 value = 'P200' )
    ( row = 3 column = 2 value = '27 Inch Display' )
    ( row = 3 column = 3 value = '4' ) ).
  TRY.
      CALL METHOD go_document->('GET_SPREADSHEET_INTERFACE')
        EXPORTING no_flush = abap_false
        IMPORTING sheet_interface = go_sheet retcode = lv_retcode.
      IF go_sheet IS NOT BOUND OR lv_retcode <> 0.
        gv_status = |Spreadsheet interface unavailable; return code { lv_retcode }|.
        RETURN.
      ENDIF.
      CALL METHOD go_sheet->('INSERT_ONE_TABLE')
        EXPORTING data_table = lt_cells fields_table = lt_fields
          rangename = 'GG_DATA' wholetable = abap_true no_flush = abap_false
        IMPORTING retcode = lv_retcode.
      gv_status = |Embedded spreadsheet created with three deterministic rows; return code { lv_retcode }|.
      gv_detail = 'Range GG_DATA demonstrates the standard Desktop Office spreadsheet table interface'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Spreadsheet population failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM show_word_document.
  DATA lv_retcode TYPE i.
  DATA lv_text TYPE string.

  PERFORM get_document USING 'Word.Document' 'GG GUI word-processing sample'.
  IF go_document IS NOT BOUND. RETURN. ENDIF.
  lv_text = |SAP GUI control sample{ cl_abap_char_utilities=>newline }|
    && |Recipient: Ada Example{ cl_abap_char_utilities=>newline }|
    && |Reference: GG-2026-001{ cl_abap_char_utilities=>newline }|
    && |This deterministic text demonstrates an embedded word-processing interface.|.
  TRY.
      CALL METHOD go_document->('GET_WORDPROCESSOR_INTERFACE')
        EXPORTING no_flush = abap_false
        IMPORTING wordprocessor_interface = go_word retcode = lv_retcode.
      IF go_word IS NOT BOUND OR lv_retcode <> 0.
        gv_status = |Word-processing interface unavailable; return code { lv_retcode }|.
        RETURN.
      ENDIF.
      CALL METHOD go_word->('INSERT_TEXT')
        EXPORTING text = lv_text no_flush = abap_false
        IMPORTING retcode = lv_retcode.
      gv_status = |Embedded word-processing document populated with deterministic merge-style fields; return code { lv_retcode }|.
      gv_detail = 'The recipient and reference values form a small mail-merge-style scenario without persistent data'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Word-processing population failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM close_document.
  DATA lv_retcode TYPE i.

  IF go_document IS BOUND.
    TRY.
        CALL METHOD go_document->('CLOSE_DOCUMENT')
          EXPORTING do_save = abap_false no_flush = abap_false
          IMPORTING retcode = lv_retcode.
        CALL METHOD go_document->('RELEASE_DOCUMENT') IMPORTING retcode = lv_retcode.
      CATCH cx_root INTO DATA(lx_error).
        gv_detail = |Document cleanup reported: { lx_error->get_text( ) }|.
    ENDTRY.
  ENDIF.
  FREE: go_sheet, go_word, go_document.
  CLEAR gv_document_kind.
ENDFORM.

FORM release_office.
  DATA lv_retcode TYPE i.

  PERFORM close_document.
  IF go_office IS BOUND.
    TRY.
        CALL METHOD go_office->('RELEASE_ALL_DOCUMENTS') IMPORTING retcode = lv_retcode.
        CALL METHOD go_office->('DESTROY_CONTROL') IMPORTING retcode = lv_retcode.
      CATCH cx_root INTO DATA(lx_error).
        gv_detail = |Office control cleanup reported: { lx_error->get_text( ) }|.
    ENDTRY.
  ENDIF.
  FREE go_office.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.

FORM audit_office.
  PERFORM detect_office.
  gv_status = |Office creator class available: { gv_available }; initialized control: { xsdbool( go_office IS BOUND ) }|.
  gv_detail = 'This legacy automation path depends on SAP GUI for Windows, registered document types, and local Office software'.
ENDFORM.

FORM show_fallback USING iv_reason TYPE string.
  DATA lt_text TYPE ty_text_lines.

  FREE go_office.
  IF go_fallback IS NOT BOUND.
    CREATE OBJECT go_fallback EXPORTING parent = go_host.
  ENDIF.
  lt_text = VALUE #(
    ( 'Desktop Office Integration is unavailable in this runtime.' )
    ( 'This optional sample requires SAP GUI for Windows and a locally installed, registered Office application.' )
    ( 'Spreadsheet, word-processing, in-place hosting, and deterministic cleanup calls remain in the native report.' ) ).
  go_fallback->set_text_as_r3table( table = lt_text ).
  go_fallback->set_readonly_mode( readonly_mode = 1 ).
  gv_status = 'Desktop Office Integration unavailable; diagnostic fallback shown'.
  gv_detail = iv_reason.
ENDFORM.
