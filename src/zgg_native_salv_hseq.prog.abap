CLASS lcl_hierseq_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_link FOR EVENT link_click OF cl_salv_events_hierseq
      IMPORTING level row column.
    METHODS on_double FOR EVENT double_click OF cl_salv_events_hierseq
      IMPORTING level row column.
ENDCLASS.

DATA go_native_hierseq TYPE REF TO cl_salv_hierseq_table.
DATA go_native_hierseq_events TYPE REF TO cl_salv_events_hierseq.
DATA go_hierseq_events TYPE REF TO lcl_hierseq_events.

CLASS lcl_hierseq_events IMPLEMENTATION.
  METHOD on_link.
    DATA lv_event TYPE c LENGTH 24 VALUE 'LINK_CLICK'.
    DATA lv_text TYPE c LENGTH 80.

    EXPORT event = lv_event level = level row = row column = column
      TO MEMORY ID 'ZGG_GUI_SALV_HIERSEQ_EVENT'.
    lv_text = |LINK_CLICK level { level }, row { row }, column { column }|.
    MESSAGE lv_text TYPE 'S'.
  ENDMETHOD.

  METHOD on_double.
    DATA lv_event TYPE c LENGTH 24 VALUE 'DOUBLE_CLICK'.
    DATA lv_text TYPE c LENGTH 80.

    EXPORT event = lv_event level = level row = row column = column
      TO MEMORY ID 'ZGG_GUI_SALV_HIERSEQ_EVENT'.
    lv_text = |DOUBLE_CLICK level { level }, row { row }, column { column }|.
    MESSAGE lv_text TYPE 'S'.
  ENDMETHOD.
ENDCLASS.

FORM register_native_hierseq_events.
  IF gv_native_events_registered = abap_true OR go_hierseq IS NOT BOUND.
    RETURN.
  ENDIF.

  TRY.
      go_native_hierseq ?= go_hierseq.
      go_native_hierseq_events = go_native_hierseq->get_event( ).
      CREATE OBJECT go_hierseq_events.
      SET HANDLER go_hierseq_events->on_link FOR go_native_hierseq_events.
      SET HANDLER go_hierseq_events->on_double FOR go_native_hierseq_events.
      gv_native_events_registered = abap_true.
    CATCH cx_root INTO DATA(lx_event_error).
      FREE: go_hierseq_events, go_native_hierseq_events, go_native_hierseq.
      CLEAR gv_native_events_registered.
      gv_detail = |Native hierseq event registration failed: { lx_event_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM unregister_hierseq_events.
  IF go_hierseq_events IS BOUND AND go_native_hierseq_events IS BOUND.
    SET HANDLER go_hierseq_events->on_link
      FOR go_native_hierseq_events ACTIVATION space.
    SET HANDLER go_hierseq_events->on_double
      FOR go_native_hierseq_events ACTIVATION space.
  ENDIF.
  FREE: go_hierseq_events, go_native_hierseq_events, go_native_hierseq.
  CLEAR gv_native_events_registered.
  FREE MEMORY ID 'ZGG_GUI_SALV_HIERSEQ_EVENT'.
ENDFORM.
