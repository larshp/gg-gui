REPORT zgg_gui_dynamic_document.

TYPES:
  BEGIN OF ty_option,
    value TYPE c LENGTH 250,
    text  TYPE string,
  END OF ty_option,
  ty_options TYPE STANDARD TABLE OF ty_option WITH EMPTY KEY.
TYPES ty_html_line TYPE c LENGTH 255.
TYPES ty_html TYPE STANDARD TABLE OF ty_html_line WITH EMPTY KEY.

DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_document TYPE REF TO object.
DATA go_right_area TYPE REF TO object.
DATA go_table TYPE REF TO object.
DATA go_table_area TYPE REF TO object.
DATA go_form TYPE REF TO object.
DATA go_link TYPE REF TO object.
DATA go_input TYPE REF TO object.
DATA go_select TYPE REF TO object.
DATA go_button TYPE REF TO object.
DATA go_fallback TYPE REF TO cl_gui_html_viewer.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_value TYPE c LENGTH 250 VALUE 'Initial form value'.
DATA gv_refresh_count TYPE i.
DATA gv_native_events_registered TYPE abap_bool.
DATA gv_document_event TYPE c LENGTH 24.
DATA gv_event_element TYPE c LENGTH 40.
DATA gv_event_value TYPE c LENGTH 250.

INCLUDE zgg_native_document.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_controls.
ENDMODULE.

MODULE dispatch_0100 INPUT.
  DATA lv_return_code TYPE i.

  IF go_document IS BOUND.
    cl_gui_cfw=>dispatch( IMPORTING return_code = lv_return_code ).
    IF lv_return_code <> cl_gui_cfw=>rc_noevent.
      gv_detail = |CFW dispatched native document event; return code { lv_return_code }|.
    ENDIF.
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
    WHEN 'REFRESH'.
      PERFORM refresh_input.
    WHEN 'BACKGROUND'.
      PERFORM set_background.
    WHEN 'PRINT'.
      PERFORM print_document.
    WHEN 'RESET'.
      PERFORM reset_document.
    WHEN 'DD_EVENT'.
      IMPORT event = gv_document_event element = gv_event_element
        value = gv_event_value FROM MEMORY ID 'ZGG_GUI_DD_EVENT'.
      FREE MEMORY ID 'ZGG_GUI_DD_EVENT'.
      IF gv_document_event = 'INPUT_ENTERED'.
        gv_value = gv_event_value.
      ENDIF.
      gv_status = |Dynamic Document event { gv_document_event } from { gv_event_element }|.
      IF gv_event_value IS INITIAL.
        gv_detail = 'The native element event reached the application event loop'.
      ELSE.
        gv_detail = |Element value: { gv_event_value }|.
      ENDIF.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  IF go_document IS BOUND OR go_fallback IS BOUND.
    RETURN.
  ENDIF.

  PERFORM create_document.
ENDFORM.

FORM create_document.
  DATA lv_class_name TYPE string VALUE 'CL_DD_DOCUMENT'.
  DATA lv_error_text TYPE string.

  TRY.
      CREATE OBJECT go_document TYPE (lv_class_name).
      PERFORM populate_document USING abap_false.
      IF gv_native_events_registered = abap_true.
        gv_status = 'Native Dynamic Document created; five element events registered'.
      ELSE.
        gv_status = 'Native Dynamic Document created; native element event handler unavailable'.
      ENDIF.
      gv_detail = 'Use Refresh value to update one retained form element without reconstructing the table'.
    CATCH cx_root INTO DATA(lx_error).
      FREE: go_document, go_right_area, go_table, go_table_area, go_form,
        go_link, go_input, go_select, go_button.
      lv_error_text = lx_error->get_text( ).
      PERFORM show_fallback USING lv_error_text.
  ENDTRY.
ENDFORM.

FORM populate_document USING iv_reuse TYPE abap_bool.
  DATA lt_options TYPE ty_options.

  lt_options = VALUE #(
    ( value = 'BASIC' text = 'Basic sample' )
    ( value = 'TABLE' text = 'Table-focused sample' )
    ( value = 'FORM' text = 'Form-focused sample' ) ).

  CALL METHOD go_document->('VERTICAL_SPLIT')
    EXPORTING split_area = go_document split_width = '72%'
    IMPORTING right_area = go_right_area.

  CALL METHOD go_document->('ADD_TEXT')
    EXPORTING text = 'SAP GUI Dynamic Documents'
      sap_style = 'HEADING' sap_emphasis = 'STRONG'.
  CALL METHOD go_document->('NEW_LINE').
  CALL METHOD go_document->('ADD_ICON')
    EXPORTING sap_icon = 'ICON_DISPLAY' sap_color = 'LIST_HEADING'.
  CALL METHOD go_document->('ADD_TEXT')
    EXPORTING text = ' Formatted text, icons, links, tables, and forms share one document.'
      sap_style = 'KEY'.
  CALL METHOD go_document->('NEW_LINE').
  CALL METHOD go_document->('ADD_LINK')
    EXPORTING name = 'SAP_HELP' url = 'https://help.sap.com'
      tooltip = 'Open SAP Help in the configured browser' text = 'Open SAP Help'
    IMPORTING link = go_link.
  CALL METHOD go_document->('UNDERLINE').

  CALL METHOD go_right_area->('ADD_TEXT')
    EXPORTING text = 'Document area' sap_style = 'GROUP_HEADING'
      sap_emphasis = 'STRONG'.
  CALL METHOD go_right_area->('NEW_LINE').
  CALL METHOD go_right_area->('ADD_TEXT')
    EXPORTING text = |User { sy-uname }| sap_style = 'KEY'.
  CALL METHOD go_right_area->('NEW_LINE').
  CALL METHOD go_right_area->('ADD_TEXT')
    EXPORTING text = |Date { sy-datum DATE = USER }|.

  CALL METHOD go_document->('ADD_TABLE')
    EXPORTING no_of_columns = 3 with_heading = abap_true
      cell_background_transparent = abap_false border = '1' width = '100%'
    IMPORTING table = go_table tablearea = go_table_area.
  CALL METHOD go_table->('SET_COLUMN_STYLE')
    EXPORTING col_no = 1 sap_style = 'KEY' sap_emphasis = 'STRONG'.
  CALL METHOD go_table->('SET_COLUMN_STYLE')
    EXPORTING col_no = 3 sap_align = 'RIGHT'.
  CALL METHOD go_table->('SET_ROW_STYLE')
    EXPORTING row_no = 2 sap_color = 'LIST_POSITIVE'.
  CALL METHOD go_table_area->('ADD_HEADING') EXPORTING text = 'Control'.
  CALL METHOD go_table_area->('ADD_HEADING') EXPORTING text = 'Purpose'.
  CALL METHOD go_table_area->('ADD_HEADING') EXPORTING text = 'State'.
  CALL METHOD go_table_area->('ADD_TEXT') EXPORTING text = 'Text'.
  CALL METHOD go_table_area->('ADD_TEXT') EXPORTING text = 'Formatted content'.
  CALL METHOD go_table_area->('ADD_TEXT') EXPORTING text = 'Ready'.
  CALL METHOD go_table_area->('NEW_ROW') EXPORTING sap_color = 'LIST_POSITIVE'.
  CALL METHOD go_table_area->('ADD_TEXT') EXPORTING text = 'Form'.
  CALL METHOD go_table_area->('ADD_TEXT') EXPORTING text = 'Interactive elements'.
  CALL METHOD go_table_area->('ADD_ICON') EXPORTING sap_icon = 'ICON_OKAY'.
  CALL METHOD go_table_area->('NEW_ROW').

  CALL METHOD go_document->('ADD_FORM') IMPORTING formarea = go_form.
  CALL METHOD go_form->('ADD_TEXT')
    EXPORTING text = 'Interactive form area: ' sap_emphasis = 'STRONG'.
  CALL METHOD go_form->('ADD_INPUT_ELEMENT')
    EXPORTING value = gv_value name = 'SAMPLE_INPUT' size = 24 maxlength = 60
    IMPORTING input_element = go_input.
  CALL METHOD go_form->('ADD_SELECT_ELEMENT')
    EXPORTING name = 'SAMPLE_SELECT' value = 'BASIC' options = lt_options
      tooltip = 'Choose a Dynamic Documents subject'
    IMPORTING select_element = go_select.
  CALL METHOD go_form->('ADD_BUTTON')
    EXPORTING label = 'Document button' sap_icon = 'ICON_EXECUTE_OBJECT'
      tooltip = 'Native CL_DD_BUTTON_ELEMENT clicked event' name = 'SAMPLE_BUTTON'
    IMPORTING button = go_button.

  PERFORM register_document_events.

  CALL METHOD go_document->('MERGE_DOCUMENT').
  CALL METHOD go_document->('DISPLAY_DOCUMENT')
    EXPORTING parent = go_host reuse_control = iv_reuse
      reuse_registration = iv_reuse.
ENDFORM.


FORM refresh_input.
  IF go_input IS NOT BOUND.
    gv_status = 'Dynamic Documents are unavailable; no form element can be refreshed'.
    RETURN.
  ENDIF.
  ADD 1 TO gv_refresh_count.
  gv_value = |Updated form value { gv_refresh_count } at { sy-uzeit TIME = USER }|.
  TRY.
      CALL METHOD go_input->('SET_VALUE') EXPORTING value = gv_value.
      CALL METHOD go_document->('MERGE_DOCUMENT').
      CALL METHOD go_document->('DISPLAY_DOCUMENT')
        EXPORTING parent = go_host reuse_control = abap_true
          reuse_registration = abap_true.
      gv_status = 'Only the retained input element value changed; table and split areas were not rebuilt'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Element refresh failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM set_background.
  IF go_document IS NOT BOUND.
    gv_status = 'Dynamic Documents are unavailable; no background can be set'.
    RETURN.
  ENDIF.
  TRY.
      CALL METHOD go_document->('SET_DOCUMENT_BACKGROUND')
        EXPORTING picture_id = 'ENJOYSAP_LOGO'.
      CALL METHOD go_document->('MERGE_DOCUMENT').
      CALL METHOD go_document->('DISPLAY_DOCUMENT')
        EXPORTING parent = go_host reuse_control = abap_true
          reuse_registration = abap_true.
      gv_status = 'BDS background ENJOYSAP_LOGO requested; availability depends on system content'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Background picture unavailable: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM print_document.
  IF go_document IS NOT BOUND.
    gv_status = 'Dynamic Documents are unavailable; no document can be printed'.
    RETURN.
  ENDIF.
  TRY.
      CALL METHOD go_document->('PRINT_DOCUMENT')
        EXPORTING reuse_control = abap_true.
      gv_status = 'The browser control print dialog was requested'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Print failed or was canceled: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM reset_document.
  CLEAR gv_refresh_count.
  gv_value = 'Initial form value'.
  IF go_document IS NOT BOUND.
    gv_status = 'Fallback page remains active because CL_DD_DOCUMENT is unavailable'.
    RETURN.
  ENDIF.
  TRY.
      PERFORM unregister_document_events.
      CALL METHOD go_document->('INITIALIZE_DOCUMENT').
      FREE: go_right_area, go_table, go_table_area, go_form, go_link,
        go_input, go_select, go_button.
      PERFORM populate_document USING abap_true.
      IF gv_native_events_registered = abap_true.
        gv_status = 'Document reset with five native element events registered'.
      ELSE.
        gv_status = 'Document reset; native element event handler unavailable'.
      ENDIF.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Document reset failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM show_fallback USING iv_error TYPE string.
  DATA lt_html TYPE ty_html.
  DATA lv_url TYPE c LENGTH 255.

  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_html = VALUE #(
    ( '<!doctype html><html><head><meta charset="utf-8"></head>' )
    ( '<body style="font-family:sans-serif;margin:24px;color:#1f2933">' )
    ( '<h2>Dynamic Documents unavailable</h2>' )
    ( '<p>This runtime does not provide a working CL_DD_DOCUMENT implementation.</p>' )
    ( '<p>The report keeps all native calls behind a capability check.</p></body></html>' ) ).
  go_fallback->load_data(
    EXPORTING type = 'text' subtype = 'html'
    IMPORTING assigned_url = lv_url
    CHANGING data_table = lt_html ).
  go_fallback->show_url( url = lv_url in_place = abap_true ).
  gv_status = 'CL_DD_DOCUMENT unavailable or nonfunctional; an HTML fallback is displayed'.
  gv_detail = iv_error.
ENDFORM.

FORM free_controls.
  PERFORM unregister_document_events.
  IF go_fallback IS BOUND.
    go_fallback->close_document( ).
    go_fallback->free( ).
    FREE go_fallback.
  ENDIF.
  FREE: go_right_area, go_table, go_table_area, go_form, go_link,
    go_input, go_select, go_button, go_document.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
