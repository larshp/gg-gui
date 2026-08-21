REPORT zgg_gui_picture.

TYPES ty_url TYPE c LENGTH 255.

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

START-OF-SELECTION.
  gv_url = p_url.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_controls.
  PERFORM describe_mode.
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
    WHEN 'ASYNC'.
      p_async = xsdbool( p_async = abap_false ).
      gv_status = |Asynchronous loading enabled: { p_async }|.
    WHEN 'MODE'.
      gv_mode = gv_mode + 1.
      IF gv_mode > cl_gui_picture=>display_mode_fit_center.
        gv_mode = cl_gui_picture=>display_mode_normal.
      ENDIF.
      go_picture->set_display_mode( display_mode = gv_mode ).
      PERFORM describe_mode.
      gv_status = |Display mode changed to { gv_mode_text }|.
    WHEN 'BORDER'.
      gv_border = xsdbool( gv_border = abap_false ).
      go_picture->set_3d_border( border = CONV #( gv_border ) ).
      gv_status = |3D border enabled: { gv_border }|.
    WHEN 'CLEAR'.
      go_picture->clear_picture( ).
      gv_status = 'Picture cleared; the last successful URL is retained'.
    WHEN 'RELOAD'.
      gv_url = gv_last_url.
      PERFORM load_picture.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  IF go_host IS BOUND.
    RETURN.
  ENDIF.

  CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  CREATE OBJECT go_picture EXPORTING parent = go_host.
  go_picture->set_display_mode( display_mode = gv_mode ).
  go_picture->set_3d_border( border = CONV #( gv_border ) ).
  gv_status = 'Choose the standard MIME image or enter a URL on the selection screen'.
  IF gv_url IS NOT INITIAL.
    PERFORM load_picture.
  ENDIF.
ENDFORM.

FORM publish_demo_mime.
  CLEAR gv_url.
  CALL FUNCTION 'DP_PUBLISH_WWW_URL'
    EXPORTING
      objid = 'HTMLCNTL_TESTHTM2_SAPLOGO'
    IMPORTING
      url = gv_url
    EXCEPTIONS
      dp_invalid_parameters = 1
      no_object = 2
      dp_error_publish = 3
      OTHERS = 4.
  IF sy-subrc <> 0.
    gv_status = |Standard MIME object could not be published; rc { sy-subrc }|.
  ENDIF.
ENDFORM.

FORM load_picture.
  DATA lv_result TYPE i.

  IF gv_url IS INITIAL.
    gv_status = 'No image URL was supplied'.
    RETURN.
  ENDIF.
  IF p_async = abap_true.
    go_picture->load_picture_from_url_async( url = gv_url ).
    gv_status = |Asynchronous image request queued: { gv_url }|.
    gv_last_url = gv_url.
  ELSE.
    go_picture->load_picture_from_url(
      EXPORTING url = gv_url
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
  IF go_picture IS BOUND.
    go_picture->free( ).
    FREE go_picture.
  ENDIF.
  IF go_host IS BOUND.
    go_host->free( ).
    FREE go_host.
  ENDIF.
ENDFORM.
