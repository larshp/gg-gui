REPORT zgg_gui_html_viewer.

TYPES ty_url TYPE c LENGTH 255.
TYPES ty_html_line TYPE c LENGTH 255.
TYPES ty_html TYPE STANDARD TABLE OF ty_html_line WITH EMPTY KEY.

PARAMETERS p_url TYPE ty_url LOWER CASE DEFAULT 'https://help.sap.com'.

CLASS lcl_events DEFINITION.
  PUBLIC SECTION.
    METHODS on_sapevent FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING action frame getdata.
ENDCLASS.

DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_viewer TYPE REF TO cl_gui_html_viewer.
DATA go_events TYPE REF TO lcl_events.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_generated_url TYPE ty_url.
DATA gv_image_url TYPE ty_url.
DATA gv_borderless TYPE abap_bool.
DATA gv_status TYPE c LENGTH 108.
DATA gv_event TYPE c LENGTH 108.
DATA gv_platform TYPE i.
DATA gv_frontend TYPE c LENGTH 60.
DATA gv_version TYPE c LENGTH 60.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_sapevent.
    gv_event = |SAPEVENT action={ action } frame={ frame } data={ getdata }|.
    cl_gui_cfw=>set_new_ok_code( 'SAPEVENT' ).
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_controls.
ENDMODULE.

MODULE dispatch_0100 INPUT.
  DATA lv_return_code TYPE i.

  cl_gui_cfw=>dispatch( IMPORTING return_code = lv_return_code ).
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
    WHEN 'GENERATE'.
      PERFORM show_generated USING abap_false.
    WHEN 'SHOW_DATA'.
      PERFORM show_generated USING abap_true.
    WHEN 'EXTERNAL'.
      go_viewer->show_url( url = p_url in_place = abap_true ).
      gv_status = |External URL requested; frontend security policy applies: { p_url }|.
    WHEN 'FRONTEND'.
      PERFORM detect_frontend.
      PERFORM show_generated USING abap_false.
      gv_status = |Frontend audit refreshed: { gv_frontend }, version { gv_version }|.
    WHEN 'BACK'.
      go_viewer->go_back( ).
      gv_status = 'Back navigation requested'.
    WHEN 'FORWARD'.
      PERFORM optional_navigation USING 'GO_FORWARD'.
    WHEN 'HOME'.
      PERFORM show_generated USING abap_false.
    WHEN 'REFRESH'.
      PERFORM optional_navigation USING 'DO_REFRESH'.
    WHEN 'CURRENT'.
      DATA lv_current TYPE ty_url.
      go_viewer->get_current_url( IMPORTING url = lv_current ).
      gv_status = |Current viewer URL: { lv_current }|.
    WHEN 'UI'.
      gv_borderless = xsdbool( gv_borderless = abap_false ).
      go_viewer->set_ui_flag(
        COND #( WHEN gv_borderless = abap_true
          THEN cl_gui_html_viewer=>uiflag_no3dborder ELSE 0 ) ).
      gv_status = |No-3D-border UI flag enabled: { gv_borderless }|.
    WHEN 'CLOSE'.
      go_viewer->close_document( ).
      CLEAR gv_generated_url.
      gv_status = 'Current HTML document and its frontend resources were closed'.
    WHEN 'RESET'.
      CLEAR: gv_event, gv_borderless.
      go_viewer->set_ui_flag( 0 ).
      PERFORM detect_frontend.
      PERFORM show_generated USING abap_false.
      gv_status = 'Generated home document, UI flags, navigation origin, and event status reset'.
    WHEN 'SAPEVENT'.
      gv_status = 'SAPEVENT was dispatched to the ABAP handler'.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  IF go_host IS BOUND.
    RETURN.
  ENDIF.

  CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  CREATE OBJECT go_viewer EXPORTING parent = go_host.
  CREATE OBJECT go_events.
  SET HANDLER go_events->on_sapevent FOR go_viewer.
  PERFORM detect_frontend.
  PERFORM publish_image.
  PERFORM show_generated USING abap_false.
ENDFORM.

FORM detect_frontend.
  DATA lt_version TYPE filetable.
  DATA lv_rc TYPE i.

  CLEAR: gv_frontend, gv_version.
  TRY.
      gv_platform = cl_gui_frontend_services=>get_platform( ).
      CASE gv_platform.
        WHEN cl_gui_frontend_services=>platform_nt351 OR
             cl_gui_frontend_services=>platform_nt40 OR
             cl_gui_frontend_services=>platform_nt50 OR
             cl_gui_frontend_services=>platform_windows95 OR
             cl_gui_frontend_services=>platform_windows98 OR
             cl_gui_frontend_services=>platform_windowsxp.
          gv_frontend = |SAP GUI for Windows platform id { gv_platform }|.
        WHEN OTHERS.
          gv_frontend = |Frontend platform id { gv_platform }|.
      ENDCASE.

      cl_gui_frontend_services=>get_gui_version(
        CHANGING version_table = lt_version rc = lv_rc ).
      LOOP AT lt_version INTO DATA(ls_version).
        IF gv_version IS INITIAL.
          gv_version = ls_version-filename.
        ELSE.
          gv_version = |{ gv_version }.{ ls_version-filename }|.
        ENDIF.
        IF sy-tabix = 3.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF gv_version IS INITIAL.
        gv_version = |not reported (rc { lv_rc })|.
      ENDIF.
    CATCH cx_root INTO DATA(lx_frontend).
      gv_frontend = 'Frontend query unavailable'.
      gv_version = lx_frontend->get_text( ).
  ENDTRY.
ENDFORM.

FORM publish_image.
  CLEAR gv_image_url.
  CALL FUNCTION 'DP_PUBLISH_WWW_URL'
    EXPORTING objid = 'HTMLCNTL_TESTHTM2_SAPLOGO'
    IMPORTING url = gv_image_url
    EXCEPTIONS dp_invalid_parameters = 1 no_object = 2
      dp_error_publish = 3 OTHERS = 4.
ENDFORM.

FORM build_html CHANGING ct_html TYPE ty_html.
  CLEAR ct_html.
  APPEND '<!doctype html><html><head><meta charset="utf-8">' TO ct_html.
  APPEND '<style>body{font-family:sans-serif;margin:24px;color:#1f2933}table{border-collapse:collapse}' TO ct_html.
  APPEND 'th,td{border:1px solid #bcc5ce;padding:6px;text-align:left}th{background:#eef2f5}</style>' TO ct_html.
  APPEND '</head><body><h2>SAP GUI HTML Viewer</h2>' TO ct_html.
  APPEND '<p>This page was generated from an ABAP internal table.</p>' TO ct_html.
  APPEND |<p><strong>Detected:</strong> { gv_frontend }; version { gv_version }</p>| TO ct_html.
  APPEND '<table><caption>Rendering and security capability matrix</caption>' TO ct_html.
  APPEND '<tr><th>Frontend</th><th>Renderer</th><th>Security and navigation</th></tr>' TO ct_html.
  APPEND '<tr><td>Windows</td><td>Configured IE or WebView2 control</td>' TO ct_html.
  APPEND '<td>External URL zones, certificates, and local policy apply</td></tr>' TO ct_html.
  APPEND '<tr><td>Java</td><td>Platform browser implementation</td>' TO ct_html.
  APPEND '<td>Rendering and supported methods can differ from Windows</td></tr>' TO ct_html.
  APPEND '<tr><td>HTML</td><td>Browser-hosted SAP GUI</td>' TO ct_html.
  APPEND '<td>Back/forward/refresh/current-URL APIs can be unavailable</td></tr></table>' TO ct_html.
  IF gv_image_url IS NOT INITIAL.
    APPEND |<img src="{ gv_image_url }" alt="Published SAP MIME object" style="max-width:240px">| TO ct_html.
  ENDIF.
  APPEND '<p><a href="SAPEVENT:DETAIL?source=generated">Send SAPEVENT to ABAP</a></p>' TO ct_html.
  APPEND '<p><a href="https://help.sap.com">Normal HTTPS link</a></p>' TO ct_html.
  APPEND '</body></html>' TO ct_html.
ENDFORM.

FORM show_generated USING iv_direct TYPE abap_bool.
  DATA lt_html TYPE ty_html.

  PERFORM build_html CHANGING lt_html.
  go_viewer->load_data(
    EXPORTING type = 'text' subtype = 'html'
    IMPORTING assigned_url = gv_generated_url
    CHANGING data_table = lt_html ).
  IF iv_direct = abap_true.
    go_viewer->show_data( url = gv_generated_url in_place = abap_true ).
    gv_status = 'Generated document displayed with SHOW_DATA'.
  ELSE.
    go_viewer->show_url( url = gv_generated_url in_place = abap_true ).
    gv_status = 'Generated document loaded with LOAD_DATA and displayed with SHOW_URL'.
  ENDIF.
ENDFORM.

FORM optional_navigation USING iv_method TYPE c.
  TRY.
      CALL METHOD go_viewer->(iv_method).
      gv_status = |Optional navigation method { iv_method } requested|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Navigation method unavailable: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM free_controls.
  IF go_viewer IS BOUND.
    go_viewer->close_document( ).
    go_viewer->free( ).
    FREE go_viewer.
  ENDIF.
  FREE go_events.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
