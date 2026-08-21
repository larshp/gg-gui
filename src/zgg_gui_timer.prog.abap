REPORT zgg_gui_timer.

TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

CLASS lcl_events DEFINITION.
  PUBLIC SECTION.
    METHODS on_finished FOR EVENT finished OF cl_gui_timer.
ENDCLASS.

DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA go_timer TYPE REF TO cl_gui_timer.
DATA go_events TYPE REF TO lcl_events.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_running TYPE abap_bool.
DATA gv_interval TYPE i VALUE 2.
DATA gv_ticks TYPE i.
DATA gv_status TYPE c LENGTH 104.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_finished.
    IF gv_running = abap_false.
      RETURN.
    ENDIF.
    ADD 1 TO gv_ticks.
    PERFORM refresh_document.
    go_timer->interval = gv_interval.
    go_timer->run( ).
    cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'TICK' ).
  ENDMETHOD.
ENDCLASS.

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
    WHEN 'START'.
      IF gv_running = abap_true.
        gv_status = 'Timer already running; no duplicate RUN call was issued'.
      ELSE.
        gv_running = abap_true.
        go_timer->interval = gv_interval.
        go_timer->run( ).
        gv_status = |Timer started with { gv_interval } second interval|.
      ENDIF.
    WHEN 'STOP'.
      gv_running = abap_false.
      go_timer->cancel( ).
      gv_status = 'Timer stopped'.
    WHEN 'FASTER'.
      gv_interval = nmax( val1 = 1 val2 = gv_interval - 1 ).
      go_timer->interval = gv_interval.
      gv_status = |Interval changed to { gv_interval } seconds|.
    WHEN 'SLOWER'.
      gv_interval = gv_interval + 1.
      go_timer->interval = gv_interval.
      gv_status = |Interval changed to { gv_interval } seconds|.
    WHEN 'RESET'.
      gv_running = abap_false.
      go_timer->cancel( ).
      gv_interval = 2.
      CLEAR gv_ticks.
      PERFORM refresh_document.
      gv_status = 'Timer stopped and initial counter state restored'.
    WHEN 'TICK'.
      gv_status = |Timer event { gv_ticks } dispatched; next interval { gv_interval } seconds|.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  IF go_host IS BOUND.
    RETURN.
  ENDIF.

  CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  CREATE OBJECT go_editor EXPORTING parent = go_host.
  CREATE OBJECT go_timer.
  CREATE OBJECT go_events.
  SET HANDLER go_events->on_finished FOR go_timer.
  PERFORM refresh_document.
  gv_status = 'Timer ready; one instance is reused for every start and interval change'.
ENDFORM.

FORM refresh_document.
  DATA lt_text TYPE ty_text_lines.

  lt_text = VALUE #(
    ( 'CL_GUI_TIMER' )
    ( |Completed ticks: { gv_ticks }| )
    ( |Current interval: { gv_interval } seconds| )
    ( |Running: { gv_running }| ) ).
  go_editor->set_text_as_r3table( table = lt_text ).
  cl_gui_cfw=>flush( ).
ENDFORM.

FORM free_controls.
  IF go_timer IS BOUND.
    gv_running = abap_false.
    go_timer->cancel( ).
    FREE go_timer.
  ENDIF.
  FREE go_events.
  IF go_editor IS BOUND. go_editor->free( ). FREE go_editor. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
