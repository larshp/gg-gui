CLASS zcl_gg_gui_demo_helper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_log_lines TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    CLASS-METHODS add_log
      IMPORTING
        event TYPE string
        max_lines TYPE i DEFAULT 12
      CHANGING
        log   TYPE ty_log_lines.

    CLASS-METHODS reset_log
      IMPORTING
        initial_event TYPE string OPTIONAL
      CHANGING
        log           TYPE ty_log_lines.
ENDCLASS.

CLASS zcl_gg_gui_demo_helper IMPLEMENTATION.
  METHOD add_log.
    APPEND |{ sy-uzeit TIME = USER }  { event }| TO log.
    IF max_lines > 0.
      WHILE lines( log ) > max_lines.
        DELETE log INDEX 1.
      ENDWHILE.
    ENDIF.
  ENDMETHOD.

  METHOD reset_log.
    CLEAR log.
    IF initial_event IS NOT INITIAL.
      add_log( EXPORTING event = initial_event CHANGING log = log ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
