REPORT zgg_gui_textedit.

TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_readonly TYPE abap_bool.
DATA gv_wrap TYPE abap_bool VALUE abap_true.
DATA gv_chrome TYPE abap_bool VALUE abap_true.
DATA gv_fixed TYPE abap_bool.
DATA gv_status TYPE c LENGTH 110.
DATA gv_info TYPE c LENGTH 110.

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
    WHEN 'READONLY'.
      gv_readonly = xsdbool( gv_readonly = abap_false ).
      go_editor->set_readonly_mode( CONV #( gv_readonly ) ).
      gv_status = |Read-only mode enabled: { gv_readonly }|.
    WHEN 'WRAP'.
      gv_wrap = xsdbool( gv_wrap = abap_false ).
      PERFORM set_wrap.
    WHEN 'CHROME'.
      gv_chrome = xsdbool( gv_chrome = abap_false ).
      go_editor->set_toolbar_mode( CONV #( gv_chrome ) ).
      go_editor->set_statusbar_mode( CONV #( gv_chrome ) ).
      gv_status = |Toolbar and status bar enabled: { gv_chrome }|.
    WHEN 'FONT'.
      gv_fixed = xsdbool( gv_fixed = abap_false ).
      go_editor->set_font_fixed( CONV #( gv_fixed ) ).
      gv_status = |Fixed-width font enabled: { gv_fixed }|.
    WHEN 'TABLE'.
      PERFORM read_as_table.
    WHEN 'STREAM'.
      PERFORM read_as_stream.
    WHEN 'POSITION'.
      PERFORM read_position.
    WHEN 'PROTECT'.
      PERFORM protect_first_line.
    WHEN 'CLEAR'.
      go_editor->delete_text( ).
      gv_status = 'All text deleted'.
    WHEN 'RESTORE'.
      PERFORM set_initial_text.
      gv_status = 'Initial document restored'.
    WHEN 'LOAD'.
      PERFORM load_file.
    WHEN 'SAVE'.
      PERFORM save_file.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  IF go_host IS BOUND.
    RETURN.
  ENDIF.

  CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  CREATE OBJECT go_editor
    EXPORTING
      parent                     = go_host
      wordwrap_mode              = cl_gui_textedit=>wordwrap_at_windowborder
      wordwrap_to_linebreak_mode = cl_gui_textedit=>false.
  PERFORM set_initial_text.
  go_editor->set_toolbar_mode( cl_gui_textedit=>true ).
  go_editor->set_statusbar_mode( cl_gui_textedit=>true ).
  gv_status = 'Editable document created with window-border wrapping'.
ENDFORM.

FORM set_initial_text.
  DATA lt_text TYPE ty_text_lines.

  lt_text = VALUE #(
    ( 'SAP GUI TextEdit Control' )
    ( 'Edit this document and compare table and stream retrieval.' )
    ( 'The file commands always open an explicit frontend chooser.' )
    ( 'The first line can be protected on frontend versions that support it.' ) ).
  go_editor->set_text_as_r3table( lt_text ).
ENDFORM.

FORM set_wrap.
  DATA lv_mode TYPE i.

  lv_mode = COND #( WHEN gv_wrap = abap_true
    THEN cl_gui_textedit=>wordwrap_at_windowborder
    ELSE cl_gui_textedit=>wordwrap_off ).
  go_editor->set_wordwrap_behavior(
    EXPORTING
      wordwrap_mode = lv_mode
      wordwrap_position = 72
      wordwrap_to_linebreak_mode = cl_gui_textedit=>false
    EXCEPTIONS error_cntl_call_method = 1 OTHERS = 2 ).
  gv_status = |Word wrap enabled: { gv_wrap }; rc { sy-subrc }|.
ENDFORM.

FORM read_as_table.
  DATA lt_text TYPE ty_text_lines.
  DATA lv_modified TYPE i.

  go_editor->get_text_as_r3table(
    EXPORTING only_when_modified = cl_gui_textedit=>false
    IMPORTING table = lt_text is_modified = lv_modified ).
  gv_status = |Table retrieval: { lines( lt_text ) } lines; modified { lv_modified }|.
  gv_info = COND #( WHEN lt_text IS INITIAL
    THEN 'No first line' ELSE |First line: { lt_text[ 1 ] }| ).
ENDFORM.

FORM read_as_stream.
  DATA lv_text TYPE string.
  DATA lv_modified TYPE i.

  go_editor->get_textstream(
    EXPORTING only_when_modified = cl_gui_textedit=>false
    IMPORTING text = lv_text is_modified = lv_modified ).
  gv_status = |Stream retrieval: { strlen( lv_text ) } characters; modified { lv_modified }|.
  gv_info = lv_text.
ENDFORM.

FORM read_position.
  DATA lv_line TYPE i.
  DATA lv_pos TYPE i.
  DATA lv_from_line TYPE i.
  DATA lv_from_pos TYPE i.
  DATA lv_to_line TYPE i.
  DATA lv_to_pos TYPE i.

  TRY.
      CALL METHOD go_editor->('GET_CURRENT_LINE')
        IMPORTING current_line = lv_line.
      CALL METHOD go_editor->('GET_CURRENT_POS')
        IMPORTING current_pos = lv_pos.
      CALL METHOD go_editor->('GET_SELECTION_POS')
        IMPORTING
          from_line = lv_from_line from_pos = lv_from_pos
          to_line = lv_to_line to_pos = lv_to_pos.
      gv_status = |Cursor { lv_line }:{ lv_pos }; selection { lv_from_line }:{ lv_from_pos }-{ lv_to_line }:{ lv_to_pos }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Position API unavailable: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM protect_first_line.
  TRY.
      CALL METHOD go_editor->('PROTECT_LINES')
        EXPORTING from_line = 1 to_line = 1 protect_mode = 1.
      gv_status = 'The first line is protected from editing'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Protected-line API unavailable: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM load_file.
  DATA lt_files TYPE filetable.
  DATA lv_count TYPE i.
  DATA lv_action TYPE i.
  DATA lv_length TYPE i.
  DATA lv_header TYPE xstring.
  DATA lt_text TYPE ty_text_lines.

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING window_title = 'Load text into the editor'
      default_extension = 'txt' file_filter = 'Text files (*.txt)|*.txt|'
    CHANGING file_table = lt_files rc = lv_count user_action = lv_action ).
  IF lv_count <= 0 OR lt_files IS INITIAL.
    gv_status = 'Open dialog cancelled'.
    RETURN.
  ENDIF.
  cl_gui_frontend_services=>gui_upload(
    EXPORTING filename = CONV #( lt_files[ 1 ]-filename ) filetype = 'ASC'
    IMPORTING filelength = lv_length header = lv_header
    CHANGING data_tab = lt_text ).
  go_editor->set_text_as_r3table( lt_text ).
  gv_status = |Loaded { lines( lt_text ) } lines and { lv_length } bytes|.
ENDFORM.

FORM save_file.
  DATA lv_filename TYPE string.
  DATA lv_path TYPE string.
  DATA lv_fullpath TYPE string.
  DATA lv_action TYPE i.
  DATA lv_modified TYPE i.
  DATA lt_text TYPE ty_text_lines.

  cl_gui_frontend_services=>file_save_dialog(
    EXPORTING window_title = 'Save editor text' default_extension = 'txt'
      default_file_name = 'sap-gui-textedit.txt'
      file_filter = 'Text files (*.txt)|*.txt|' prompt_on_overwrite = abap_true
    CHANGING filename = lv_filename path = lv_path fullpath = lv_fullpath
      user_action = lv_action ).
  IF lv_fullpath IS INITIAL.
    gv_status = 'Save dialog cancelled'.
    RETURN.
  ENDIF.
  go_editor->get_text_as_r3table(
    EXPORTING only_when_modified = cl_gui_textedit=>false
    IMPORTING table = lt_text is_modified = lv_modified ).
  cl_gui_frontend_services=>gui_download(
    EXPORTING filename = lv_fullpath filetype = 'ASC' confirm_overwrite = abap_true
    CHANGING data_tab = lt_text ).
  gv_status = |Saved { lines( lt_text ) } lines to { lv_fullpath }|.
ENDFORM.

FORM free_controls.
  IF go_editor IS BOUND. go_editor->free( ). FREE go_editor. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
