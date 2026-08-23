REPORT zgg_gui_graphics.

TYPES:
  BEGIN OF ty_bar,
    label TYPE c LENGTH 24,
    value TYPE i,
    group TYPE c LENGTH 12,
  END OF ty_bar,
  ty_bars TYPE STANDARD TABLE OF ty_bar WITH EMPTY KEY.
TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_control TYPE REF TO cl_gui_control.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_active_class TYPE string.
DATA gv_barchart TYPE abap_bool.
DATA gv_chart_engine TYPE abap_bool.
DATA gv_graphics_proxy TYPE abap_bool.
DATA gv_selector TYPE abap_bool.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
    PERFORM audit_controls.
    PERFORM show_audit.
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
    WHEN 'BARCHART'.
      PERFORM show_barchart.
    WHEN 'CHART'.
      PERFORM show_chart_engine.
    WHEN 'PROXY'.
      PERFORM show_graphics_proxy.
    WHEN 'SELECTOR'.
      PERFORM show_selector.
    WHEN 'AUDIT'.
      PERFORM audit_controls.
      PERFORM show_audit.
    WHEN 'RESET'.
      PERFORM release_active.
      PERFORM audit_controls.
      PERFORM show_audit.
  ENDCASE.
ENDMODULE.

FORM class_exists USING iv_class TYPE string CHANGING cv_exists TYPE abap_bool.
  DATA lo_descr TYPE REF TO cl_abap_typedescr.

  cv_exists = abap_false.
  TRY.
      lo_descr = cl_abap_classdescr=>describe_by_name( iv_class ).
      cv_exists = xsdbool( lo_descr IS BOUND ).
    CATCH cx_root.
      cv_exists = abap_false.
  ENDTRY.
ENDFORM.

FORM audit_controls.
  PERFORM class_exists USING 'CL_GUI_BARCHART' CHANGING gv_barchart.
  PERFORM class_exists USING 'CL_GUI_CHART_ENGINE' CHANGING gv_chart_engine.
  PERFORM class_exists USING 'CL_GUI_GP_PRES' CHANGING gv_graphics_proxy.
  PERFORM class_exists USING 'CL_GUI_SELECTOR' CHANGING gv_selector.
  gv_status = |Installed classes: bar { gv_barchart }, chart engine { gv_chart_engine }, proxy { gv_graphics_proxy }, selector { gv_selector }|.
  gv_detail = 'Bar/proxy are legacy GFW controls; chart engine uses ActiveX or IGS; selector is installation dependent'.
ENDFORM.

FORM show_barchart.
  DATA lt_bars TYPE ty_bars.
  DATA lv_class TYPE string VALUE 'CL_GUI_BARCHART'.
  DATA lo_barchart TYPE REF TO cl_gui_barchart.
  DATA lv_reason TYPE string.

  PERFORM release_active.
  IF gv_barchart = abap_false.
    PERFORM show_missing USING lv_class 'Legacy SAP GUI bar-chart wrapper is not installed'.
    RETURN.
  ENDIF.
  lt_bars = VALUE #(
    ( label = 'Mechanical Keyboard' value = 12 group = 'Input' )
    ( label = 'Ergonomic Mouse' value = 7 group = 'Input' )
    ( label = '27 Inch Display' value = 4 group = 'Display' ) ).
  TRY.
      CREATE OBJECT lo_barchart EXPORTING parent = go_host.
      lo_barchart->display( ).
      go_control = lo_barchart.
      gv_active_class = lv_class.
      gv_status = |CL_GUI_BARCHART hosted; { lines( lt_bars ) } deterministic categories prepared|.
      gv_detail = 'Legacy SAP GUI control; its data-transfer interface is release dependent and not part of the checked surface'.
    CATCH cx_root INTO DATA(lx_error).
      lv_reason = lx_error->get_text( ).
      PERFORM show_missing USING lv_class lv_reason.
  ENDTRY.
ENDFORM.

FORM show_chart_engine.
  DATA lv_class TYPE string VALUE 'CL_GUI_CHART_ENGINE'.
  DATA lo_engine TYPE REF TO cl_gui_chart_engine.
  DATA lv_xml TYPE string.
  DATA lv_reason TYPE string.

  PERFORM release_active.
  IF gv_chart_engine = abap_false.
    PERFORM show_missing USING lv_class 'SAP GUI Chart Engine class is not installed'.
    RETURN.
  ENDIF.
  lv_xml = '<?xml version="1.0" encoding="utf-8"?>'
    && '<Chart><Data><Series label="Quantity">'
    && '<Point label="Keyboard" value="12"/><Point label="Mouse" value="7"/>'
    && '<Point label="Display" value="4"/></Series></Data></Chart>'.
  TRY.
      CREATE OBJECT lo_engine EXPORTING parent = go_host.
      lo_engine->set_data( lv_xml ).
      lo_engine->render( ).
      go_control = lo_engine.
      gv_active_class = lv_class.
      gv_status = 'CL_GUI_CHART_ENGINE created with deterministic XML chart data'.
      gv_detail = 'SAP GUI for Windows uses the ActiveX engine when present and can fall back to the IGS implementation'.
    CATCH cx_root INTO DATA(lx_error).
      lv_reason = lx_error->get_text( ).
      PERFORM show_missing USING lv_class lv_reason.
  ENDTRY.
ENDFORM.

FORM show_graphics_proxy.
  DATA lv_class TYPE string VALUE 'CL_GUI_GP_PRES'.
  DATA lo_proxy TYPE REF TO cl_gui_gp_pres.
  DATA lv_reason TYPE string.
  DATA lv_retval TYPE i.

  PERFORM release_active.
  IF gv_graphics_proxy = abap_false.
    PERFORM show_missing USING lv_class 'Graphical Framework business-graphics proxy is not installed'.
    RETURN.
  ENDIF.
  TRY.
* CL_GUI_GP_PRES declares no constructor parameters in the dependency surface.
      CREATE OBJECT lo_proxy.
      lo_proxy->set_dc_names(
        EXPORTING objid  = 'OBJID'
                  grpid  = 'GRPID'
                  x_val  = 'X_VAL'
                  y_val  = 'Y_VAL'
        IMPORTING retval = lv_retval ).
      lo_proxy->if_graphic_proxy~activate( IMPORTING retval = lv_retval ).
      go_control = lo_proxy.
      gv_active_class = lv_class.
      gv_status = |CL_GUI_GP_PRES business-graphics proxy activated; return code { lv_retval }|.
      gv_detail = 'Native applications normally connect a GFW data-container implementation before activating the proxy'.
    CATCH cx_root INTO DATA(lx_error).
      lv_reason = lx_error->get_text( ).
      PERFORM show_missing USING lv_class lv_reason.
  ENDTRY.
ENDFORM.

FORM show_selector.
  DATA lv_class TYPE string VALUE 'CL_GUI_SELECTOR'.
  DATA lo_selector TYPE REF TO cl_gui_selector.
  DATA lv_reason TYPE string.

  PERFORM release_active.
  IF gv_selector = abap_false.
    PERFORM show_missing USING lv_class 'SAP GUI color-selector control is not installed'.
    RETURN.
  ENDIF.
  TRY.
      CREATE OBJECT lo_selector EXPORTING parent = go_host.
      go_control = lo_selector.
      gv_active_class = lv_class.
      gv_status = 'CL_GUI_SELECTOR hosted in the sample container'.
      gv_detail = 'Color selector used by classic form tools; its colour-transfer interface is release dependent and not part of the checked surface'.
    CATCH cx_root INTO DATA(lx_error).
      lv_reason = lx_error->get_text( ).
      PERFORM show_missing USING lv_class lv_reason.
  ENDTRY.
ENDFORM.

FORM show_audit.
  DATA lt_text TYPE ty_text_lines.

  PERFORM release_active.
  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( 'Runtime capability audit for optional SAP graphics controls' )
    ( |CL_GUI_BARCHART: { gv_barchart } - legacy SAP GUI bar-chart wrapper| )
    ( |CL_GUI_CHART_ENGINE: { gv_chart_engine } - ActiveX with possible IGS fallback| )
    ( |CL_GUI_GP_PRES: { gv_graphics_proxy } - Graphical Framework business-graphics proxy| )
    ( |CL_GUI_SELECTOR: { gv_selector } - installed color selector| )
    ( 'Choose a variant to create it; missing classes and construction failures remain nonfatal.' ) ).
  go_fallback->set_text_as_r3table( lt_text ).
  go_fallback->set_readonly_mode( 1 ).
ENDFORM.

FORM show_missing USING iv_class TYPE string iv_reason TYPE string.
  DATA lt_text TYPE ty_text_lines.

  PERFORM release_active.
  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( |{ iv_class } is unavailable or could not be initialized.| )
    ( |Reason: { iv_reason }| )
    ( 'Use the availability audit to compare installed controls; no optional class is assumed.' ) ).
  go_fallback->set_text_as_r3table( lt_text ).
  go_fallback->set_readonly_mode( 1 ).
  gv_status = |{ iv_class } unavailable; diagnostic fallback shown|.
  gv_detail = iv_reason.
ENDFORM.

FORM release_active.
  IF go_control IS BOUND.
    go_control->free( ).
    FREE go_control.
  ENDIF.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  CLEAR gv_active_class.
ENDFORM.

FORM free_controls.
  PERFORM release_active.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
