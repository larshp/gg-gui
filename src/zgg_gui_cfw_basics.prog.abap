REPORT zgg_gui_cfw_basics.

TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

CLASS lcl_log DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS add IMPORTING text TYPE string.
ENDCLASS.

CLASS lcl_events DEFINITION.
  PUBLIC SECTION.
    METHODS on_timer FOR EVENT finished OF cl_gui_timer.
ENDCLASS.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA go_timer TYPE REF TO cl_gui_timer.
DATA go_events TYPE REF TO lcl_events.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_visible TYPE abap_bool VALUE abap_true.
DATA gv_enabled TYPE abap_bool VALUE abap_true.
DATA gv_application_event TYPE abap_bool VALUE abap_true.
DATA gv_timer_ticks TYPE i.
DATA gv_log1 TYPE c LENGTH 55.
DATA gv_log2 TYPE c LENGTH 55.
DATA gv_log3 TYPE c LENGTH 55.
DATA gv_log4 TYPE c LENGTH 55.
DATA gv_log5 TYPE c LENGTH 55.
DATA gv_log6 TYPE c LENGTH 55.

CLASS lcl_log IMPLEMENTATION.
  METHOD add.
    gv_log6 = gv_log5.
    gv_log5 = gv_log4.
    gv_log4 = gv_log3.
    gv_log3 = gv_log2.
    gv_log2 = gv_log1.
    gv_log1 = |{ sy-uzeit TIME = USER }  { text }|.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_timer.
    ADD 1 TO gv_timer_ticks.
    lcl_log=>add( |Application event: timer tick { gv_timer_ticks }| ).
    cl_gui_cfw=>set_new_ok_code(
      EXPORTING new_code = 'TIMER'
      IMPORTING rc       = DATA(lv_rc) ).
    IF lv_rc <> 0.
      lcl_log=>add( |SET_NEW_OK_CODE returned { lv_rc }| ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  lcl_log=>add( 'PBO: reuse or create controls' ).
  PERFORM create_controls.
ENDMODULE.

MODULE dispatch_0100 INPUT.
  DATA lv_return_code TYPE i.

  cl_gui_cfw=>dispatch( IMPORTING return_code = lv_return_code ).
  IF lv_return_code <> cl_gui_cfw=>rc_noevent.
    lcl_log=>add( |CFW dispatch returned { lv_return_code }| ).
  ENDIF.
ENDMODULE.

MODULE exit_0100 INPUT.
  PERFORM free_controls.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.
  DATA lv_valid TYPE i.
  DATA lv_width TYPE i.
  DATA lv_height TYPE i.
  DATA lv_pixels TYPE i.
  DATA lo_focus TYPE REF TO cl_gui_control.

  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_ok_code.
    WHEN 'FOCUS'.
      cl_gui_control=>set_focus( go_editor ).
      cl_gui_control=>get_focus( IMPORTING control = lo_focus ).
      IF lo_focus IS BOUND.
        lcl_log=>add( 'Focus set and active control returned' ).
      ELSE.
        lcl_log=>add( 'No active control returned' ).
      ENDIF.
    WHEN 'VISIBLE'.
      gv_visible = xsdbool( gv_visible = abap_false ).
      go_editor->set_visible( gv_visible ).
      lcl_log=>add( |Visible state: { gv_visible }| ).
    WHEN 'ENABLE'.
      gv_enabled = xsdbool( gv_enabled = abap_false ).
      go_editor->set_enable( gv_enabled ).
      lcl_log=>add( |Enabled state: { gv_enabled }| ).
    WHEN 'EVENT'.
      gv_application_event = xsdbool( gv_application_event = abap_false ).
      PERFORM register_events.
      lcl_log=>add( |Application event flag: { gv_application_event }| ).
    WHEN 'RESIZE'.
      go_editor->set_alignment(
        cl_gui_control=>align_at_left + cl_gui_control=>align_at_top ).
      go_editor->set_position( left   = 8
                               top    = 8
                               width  = 420
                               height = 220 ).
      go_editor->get_width( IMPORTING width = lv_width ).
      go_editor->get_height( IMPORTING height = lv_height ).
      cl_gui_cfw=>flush( ).
      lv_pixels = cl_gui_cfw=>compute_pixel_from_metric(
        x_or_y = 'X'
        in     = 100 ).
      lcl_log=>add( |Size { lv_width }x{ lv_height }; metric { lv_pixels }| ).
    WHEN 'TIMER'.
      lcl_log=>add( 'Timer PAI round trip completed' ).
    WHEN 'RUN_TIMER'.
      go_timer->interval = 1.
      go_timer->run( ).
      lcl_log=>add( 'Timer started with one-second interval' ).
    WHEN 'REFRESH'.
      go_editor->is_valid( IMPORTING result = lv_valid ).
      cl_gui_cfw=>flush( ).
      CALL METHOD cl_gui_cfw=>update_view
        EXCEPTIONS
          cntl_system_error = 1
          cntl_error        = 2
          OTHERS            = 3.
      lcl_log=>add( |Validity { lv_valid }; UPDATE_VIEW rc { sy-subrc }| ).
    WHEN 'RESET'.
      gv_visible = abap_true.
      gv_enabled = abap_true.
      gv_application_event = abap_true.
      CLEAR gv_timer_ticks.
      go_editor->set_visible( gv_visible ).
      go_editor->set_enable( gv_enabled ).
      PERFORM register_events.
      PERFORM set_initial_text.
      lcl_log=>add( 'Initial control state restored' ).
  ENDCASE.
ENDMODULE.

FORM create_controls.
  IF go_container IS BOUND.
    RETURN.
  ENDIF.

  CREATE OBJECT go_container
    EXPORTING
      container_name = 'CC_MAIN'.
  CREATE OBJECT go_editor
    EXPORTING
      parent = go_container.
  CREATE OBJECT go_timer.
  CREATE OBJECT go_events.
  SET HANDLER go_events->on_timer FOR go_timer.

  PERFORM register_events.
  PERFORM set_initial_text.
  lcl_log=>add( |ActiveX={ cl_gui_object=>activex } JavaBean={ cl_gui_object=>javabean } WWW={ cl_gui_object=>www_active }| ).
  lcl_log=>add( 'Controls created once' ).
ENDFORM.

FORM register_events.
  DATA lt_events TYPE cntl_simple_events.

  lt_events = VALUE #( ( eventid = cl_gui_textedit=>event_double_click
    appl_event                   = gv_application_event ) ).
  go_editor->set_registered_events( lt_events ).
ENDFORM.

FORM set_initial_text.
  DATA lt_text TYPE ty_text_lines.

  lt_text = VALUE #(
    ( 'Control Framework lifecycle sample' )
    ( 'The editor is created once and reused on every PBO.' )
    ( 'Use the screen buttons to change frontend control state.' ) ).
  go_editor->set_text_as_r3table( lt_text ).
ENDFORM.

FORM free_controls.
  IF go_timer IS BOUND.
    go_timer->cancel( ).
    FREE go_timer.
  ENDIF.
  IF go_editor IS BOUND.
    go_editor->free( ).
    FREE go_editor.
  ENDIF.
  IF go_container IS BOUND.
    go_container->free( ).
    FREE go_container.
  ENDIF.
  FREE go_events.
ENDFORM.
