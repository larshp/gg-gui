CLASS zcl_gg_gui_demo_helper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_log_lines TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    CLASS-METHODS add_log
      IMPORTING
        event TYPE string
      CHANGING
        log   TYPE ty_log_lines.
ENDCLASS.

CLASS zcl_gg_gui_demo_helper IMPLEMENTATION.
  METHOD add_log.
    APPEND |{ sy-uzeit TIME = USER }  { event }| TO log.
  ENDMETHOD.
ENDCLASS.
