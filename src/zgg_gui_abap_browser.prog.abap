REPORT zgg_gui_abap_browser.

DATA go_host TYPE REF TO cl_gui_container.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 100.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host TYPE cl_gui_custom_container
      EXPORTING container_name = 'CC_MAIN'.
    PERFORM show_html USING go_host abap_false.
  ENDIF.
ENDMODULE.

MODULE exit_0100 INPUT.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.

  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_ok_code.
    WHEN 'HTML_CONTAINER'.
      PERFORM show_html USING go_host abap_false.
    WHEN 'HTML_DIALOG'.
      PERFORM show_html USING cl_gui_container=>default_screen abap_true.
    WHEN 'HTML_FULL'.
      PERFORM show_html USING cl_gui_container=>default_screen abap_false.
    WHEN 'XML_STRING'.
      PERFORM show_xml_string.
    WHEN 'XML_XSTRING'.
      PERFORM show_xml_xstring.
    WHEN 'MALFORMED'.
      PERFORM show_malformed.
    WHEN 'EMPTY'.
      PERFORM show_empty.
  ENDCASE.
ENDMODULE.

FORM show_html USING io_container TYPE REF TO cl_gui_container
                     iv_dialog TYPE abap_bool.
  DATA lv_html TYPE string.

  lv_html = '<html><body style="font-family:sans-serif">'
    && '<h2>CL_ABAP_BROWSER</h2>'
    && '<p>HTML supplied directly as an ABAP string.</p>'
    && '<p>The same content can use a supplied container, a dialog, or the default screen.</p>'
    && '</body></html>'.
  TRY.
      cl_abap_browser=>show_html(
        html_string = lv_html
        title       = 'ABAP Browser HTML'
        container   = io_container
        dialog      = iv_dialog
        printing    = abap_true ).
      gv_status = |HTML displayed; dialog={ iv_dialog }, supplied container={ xsdbool( io_container IS BOUND ) }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |SHOW_HTML failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM show_xml_string.
  DATA lv_xml TYPE string.

  lv_xml = '<?xml version="1.0"?><catalog><sample id="1">String XML</sample></catalog>'.
  TRY.
      cl_abap_browser=>show_xml(
        xml_string = lv_xml
        title      = 'XML from STRING'
        container  = go_host
        printing   = abap_true ).
      gv_status = 'Well-formed XML STRING displayed in the supplied container'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |SHOW_XML with STRING failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM show_xml_xstring.
  DATA lv_xml TYPE string.
  DATA lv_xxml TYPE xstring.

  lv_xml = '<?xml version="1.0" encoding="utf-8"?><catalog><sample id="2">XSTRING XML</sample></catalog>'.
  lv_xxml = cl_abap_codepage=>convert_to( lv_xml ).
  TRY.
      cl_abap_browser=>show_xml(
        xml_string  = ''
        xml_xstring = lv_xxml
        title       = 'XML from XSTRING'
        container   = go_host
        printing    = abap_true ).
      gv_status = |XML XSTRING displayed; byte length { xstrlen( lv_xxml ) }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |SHOW_XML with XSTRING failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM show_malformed.
  TRY.
      cl_abap_browser=>show_xml(
        xml_string = '<catalog><unclosed>'
        title      = 'Malformed XML'
        container  = go_host
        dialog     = abap_false ).
      gv_status = 'Malformed XML was passed without terminating the caller'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Malformed XML was rejected safely: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM show_empty.
  TRY.
      cl_abap_browser=>show_html(
        html_string = ''
        title       = 'Empty HTML'
        container   = go_host
        dialog      = abap_false ).
      gv_status = 'Empty HTML was passed without terminating the caller'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Empty HTML was rejected safely: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.
