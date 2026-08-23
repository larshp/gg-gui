REPORT zgg_gui_picture.

TYPES ty_url TYPE c LENGTH 255.
TYPES ty_blob_line TYPE x LENGTH 255.

PARAMETERS:
  p_url TYPE ty_url LOWER CASE,
  p_async AS CHECKBOX DEFAULT abap_false.

DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_picture TYPE REF TO cl_gui_picture.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_url TYPE ty_url.
DATA gv_last_url TYPE ty_url.
DATA gv_mode TYPE i VALUE cl_gui_picture=>display_mode_fit_center.
DATA gv_mode_text TYPE c LENGTH 26.
DATA gv_border TYPE abap_bool VALUE abap_true.
DATA gv_status TYPE c LENGTH 100.
DATA gv_native_events_registered TYPE abap_bool.
DATA gv_picture_event TYPE c LENGTH 24.
DATA gv_mouse_x TYPE i.
DATA gv_mouse_y TYPE i.

INCLUDE zgg_native_picture.

START-OF-SELECTION.
  gv_url = p_url.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_controls.
  PERFORM describe_mode.
ENDMODULE.

MODULE dispatch_0100 INPUT.
  DATA lv_dispatch_rc TYPE i.

  IF go_picture IS BOUND AND gv_native_events_registered = abap_true.
    cl_gui_cfw=>dispatch( IMPORTING return_code = lv_dispatch_rc ).
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
    WHEN 'MIME'.
      PERFORM publish_demo_mime.
      IF gv_url IS NOT INITIAL.
        PERFORM load_picture.
      ENDIF.
    WHEN 'URL'.
      gv_url = p_url.
      PERFORM load_picture.
    WHEN 'BMP' OR 'JPG' OR 'GIF'.
      PERFORM publish_format_fixture USING lv_ok_code.
    WHEN 'ASYNC'.
      p_async = xsdbool( p_async = abap_false ).
      gv_status = |Asynchronous loading enabled: { p_async }|.
    WHEN 'MODE'.
      gv_mode = gv_mode + 1.
      IF gv_mode > cl_gui_picture=>display_mode_fit_center.
        gv_mode = cl_gui_picture=>display_mode_normal.
      ENDIF.
      go_picture->set_display_mode( gv_mode ).
      PERFORM describe_mode.
      gv_status = |Display mode changed to { gv_mode_text }|.
    WHEN 'BORDER'.
      gv_border = xsdbool( gv_border = abap_false ).
      go_picture->set_3d_border(
        COND i( WHEN gv_border = abap_true THEN 1 ELSE 0 ) ).
      gv_status = |3D border enabled: { gv_border }|.
    WHEN 'CLEAR'.
      go_picture->clear_picture( ).
      gv_status = 'Picture cleared; the last successful URL is retained'.
    WHEN 'RELOAD'.
      gv_url = gv_last_url.
      PERFORM load_picture.
    WHEN 'RESET'.
      p_async = abap_false.
      gv_mode = cl_gui_picture=>display_mode_fit_center.
      gv_border = abap_true.
      go_picture->set_display_mode( gv_mode ).
      go_picture->set_3d_border( 1 ).
      PERFORM publish_demo_mime.
      IF gv_url IS NOT INITIAL.
        PERFORM load_picture.
      ENDIF.
      PERFORM describe_mode.
      gv_status = 'Picture source, synchronous loading, fit mode, and border reset'.
    WHEN 'PIC_EVENT'.
      IMPORT event = gv_picture_event
        mouse_pos_x = gv_mouse_x mouse_pos_y = gv_mouse_y
        FROM MEMORY ID 'ZGG_GUI_PICTURE_EVENT'.
      FREE MEMORY ID 'ZGG_GUI_PICTURE_EVENT'.
      gv_status = |{ gv_picture_event } at original-image coordinate { gv_mouse_x },{ gv_mouse_y }|.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  IF go_host IS BOUND.
    RETURN.
  ENDIF.

  CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  CREATE OBJECT go_picture EXPORTING parent = go_host.
  go_picture->set_display_mode( gv_mode ).
  go_picture->set_3d_border(
    COND i( WHEN gv_border = abap_true THEN 1 ELSE 0 ) ).
  PERFORM register_native_picture_events.
  IF gv_native_events_registered = abap_true.
    gv_status = 'Picture click and double-click events registered; choose an image source'.
  ELSE.
    gv_status = 'Picture events unavailable; loading and display behavior remains active'.
  ENDIF.
  IF gv_url IS NOT INITIAL.
    PERFORM load_picture.
  ENDIF.
ENDFORM.


FORM publish_format_fixture USING iv_format TYPE sy-ucomm.
  DATA lv_base64 TYPE string.
  DATA lv_blob TYPE xstring.
  DATA lv_size TYPE i.
  DATA lv_subtype TYPE string.
  DATA lv_provider_url TYPE c LENGTH 255.
  DATA lt_data TYPE STANDARD TABLE OF ty_blob_line WITH EMPTY KEY.

  CASE iv_format.
    WHEN 'BMP'.
      lv_subtype = 'bmp'.
      lv_base64 =
        `Qk1GAAAAAAAAADYAAAAoAAAAAgAAAAIAAAABABgAAAAAAAAAAADEDgAAxA4A` &&
        `AAAAAAAAAAAAtG4UtG4UAAC0bhS0bhQAAA==`.
    WHEN 'GIF'.
      lv_subtype = 'gif'.
      lv_base64 =
        `R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==`.
    WHEN 'JPG'.
      lv_subtype = 'jpeg'.
      lv_base64 =
        `/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgF` &&
        `BQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYU` &&
        `GBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQU` &&
        `FBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAAIAAgD` &&
        `ASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL` &&
        `/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKB` &&
        `kaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdI` &&
        `SUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZ` &&
        `mqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl` &&
        `5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQF` &&
        `BgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdh` &&
        `cRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5` &&
        `OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImK` &&
        `kpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX` &&
        `2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwDxyiiiv6FP` &&
        `53P/2Q==`.
  ENDCASE.

  CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
    EXPORTING input = lv_base64
    IMPORTING output = lv_blob
    EXCEPTIONS failed = 1 OTHERS = 2.
  IF sy-subrc <> 0.
    gv_status = |Could not decode the bundled { iv_format } fixture|.
    RETURN.
  ENDIF.

  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING buffer        = lv_blob
    IMPORTING output_length = lv_size
    TABLES binary_tab       = lt_data.

  CLEAR: gv_url, lv_provider_url.
  CALL FUNCTION 'DP_CREATE_URL'
    EXPORTING
      type            = 'image'
      subtype         = lv_subtype
      size            = lv_size
      lifetime        = 'T'
    TABLES data       = lt_data
    CHANGING url      = lv_provider_url
    EXCEPTIONS OTHERS = 1.
  IF sy-subrc <> 0 OR lv_provider_url IS INITIAL.
    gv_status = |Data Provider could not publish the { iv_format } fixture|.
    RETURN.
  ENDIF.
  gv_url = lv_provider_url.

  PERFORM load_picture.
  gv_status = |Bundled { iv_format } fixture published and loaded ({ lv_size } bytes)|.
ENDFORM.

FORM publish_demo_mime.
  DATA lv_provider_url TYPE c LENGTH 255.

  CLEAR: gv_url, lv_provider_url.
  CALL FUNCTION 'DP_PUBLISH_WWW_URL'
    EXPORTING
      objid                 = 'HTMLCNTL_TESTHTM2_SAPLOGO'
      lifetime              = 'T'
    IMPORTING
      url                   = lv_provider_url
    EXCEPTIONS
      dp_invalid_parameters = 1
      no_object             = 2
      dp_error_publish      = 3
      OTHERS                = 4.
  IF sy-subrc <> 0.
    gv_status = |Standard MIME object could not be published; rc { sy-subrc }|.
    RETURN.
  ENDIF.
  gv_url = lv_provider_url.
ENDFORM.

FORM load_picture.
  DATA lv_result TYPE i.

  IF gv_url IS INITIAL.
    gv_status = 'No image URL was supplied'.
    RETURN.
  ENDIF.
  IF p_async = abap_true.
    go_picture->load_picture_from_url_async( gv_url ).
    gv_status = |Asynchronous image request queued: { gv_url }|.
    gv_last_url = gv_url.
  ELSE.
    go_picture->load_picture_from_url(
      EXPORTING url    = gv_url
      IMPORTING result = lv_result ).
    IF lv_result = 0.
      gv_status = |Synchronous load failed or source was rejected: { gv_url }|.
    ELSE.
      gv_status = |Synchronous image loaded: { gv_url }|.
      gv_last_url = gv_url.
    ENDIF.
  ENDIF.
ENDFORM.

FORM describe_mode.
  CASE gv_mode.
    WHEN cl_gui_picture=>display_mode_normal.
      gv_mode_text = 'Normal'.
    WHEN cl_gui_picture=>display_mode_stretch.
      gv_mode_text = 'Stretch'.
    WHEN cl_gui_picture=>display_mode_fit.
      gv_mode_text = 'Fit / keep aspect'.
    WHEN cl_gui_picture=>display_mode_normal_center.
      gv_mode_text = 'Normal, centered'.
    WHEN cl_gui_picture=>display_mode_fit_center.
      gv_mode_text = 'Fit, centered'.
  ENDCASE.
ENDFORM.

FORM free_controls.
  PERFORM unregister_picture_events.
  IF go_picture IS BOUND.
    go_picture->free( ).
    FREE go_picture.
  ENDIF.
  IF go_host IS BOUND.
    go_host->free( ).
    FREE go_host.
  ENDIF.
ENDFORM.
