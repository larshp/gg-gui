CLASS lcl_document_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_link FOR EVENT clicked OF cl_dd_link_element IMPORTING sender.
    METHODS on_button FOR EVENT clicked OF cl_dd_button_element IMPORTING sender.
    METHODS on_entered FOR EVENT entered OF cl_dd_input_element IMPORTING sender.
    METHODS on_help FOR EVENT help_f1 OF cl_dd_input_element IMPORTING sender.
    METHODS on_selected FOR EVENT selected OF cl_dd_select_element IMPORTING sender.
ENDCLASS.

DATA go_native_link TYPE REF TO cl_dd_link_element.
DATA go_native_button TYPE REF TO cl_dd_button_element.
DATA go_native_input TYPE REF TO cl_dd_input_element.
DATA go_native_select TYPE REF TO cl_dd_select_element.
DATA go_document_events TYPE REF TO lcl_document_events.

CLASS lcl_document_events IMPLEMENTATION.
  METHOD on_link.
    DATA lv_event TYPE c LENGTH 24 VALUE 'LINK_CLICKED'.
    DATA lv_value TYPE c LENGTH 250.

    EXPORT event = lv_event element = sender->name value = lv_value
      TO MEMORY ID 'ZGG_GUI_DD_EVENT'.
    cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'DD_EVENT' ).
  ENDMETHOD.

  METHOD on_button.
    DATA lv_event TYPE c LENGTH 24 VALUE 'BUTTON_CLICKED'.
    DATA lv_value TYPE c LENGTH 250.

    EXPORT event = lv_event element = sender->name value = lv_value
      TO MEMORY ID 'ZGG_GUI_DD_EVENT'.
    cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'DD_EVENT' ).
  ENDMETHOD.

  METHOD on_entered.
    DATA lv_event TYPE c LENGTH 24 VALUE 'INPUT_ENTERED'.

    EXPORT event = lv_event element = sender->name value = sender->value
      TO MEMORY ID 'ZGG_GUI_DD_EVENT'.
    cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'DD_EVENT' ).
  ENDMETHOD.

  METHOD on_help.
    DATA lv_event TYPE c LENGTH 24 VALUE 'INPUT_HELP_F1'.

    EXPORT event = lv_event element = sender->name value = sender->value
      TO MEMORY ID 'ZGG_GUI_DD_EVENT'.
    cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'DD_EVENT' ).
  ENDMETHOD.

  METHOD on_selected.
    DATA lv_event TYPE c LENGTH 24 VALUE 'SELECT_SELECTED'.

    EXPORT event = lv_event element = sender->name value = sender->value
      TO MEMORY ID 'ZGG_GUI_DD_EVENT'.
    cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'DD_EVENT' ).
  ENDMETHOD.
ENDCLASS.

FORM register_document_events.
  IF gv_native_events_registered = abap_true OR go_link IS NOT BOUND.
    RETURN.
  ENDIF.

  TRY.
      go_native_link ?= go_link.
      go_native_button ?= go_button.
      go_native_input ?= go_input.
      go_native_select ?= go_select.
      CREATE OBJECT go_document_events.
      SET HANDLER go_document_events->on_link FOR go_native_link.
      SET HANDLER go_document_events->on_button FOR go_native_button.
      SET HANDLER go_document_events->on_entered FOR go_native_input.
      SET HANDLER go_document_events->on_help FOR go_native_input.
      SET HANDLER go_document_events->on_selected FOR go_native_select.
      gv_native_events_registered = abap_true.
    CATCH cx_root INTO DATA(lx_event_error).
      FREE: go_document_events, go_native_link, go_native_button,
        go_native_input, go_native_select.
      CLEAR gv_native_events_registered.
      gv_status = |Native document event registration failed: { lx_event_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM unregister_document_events.
  IF go_document_events IS BOUND.
    IF go_native_link IS BOUND.
      SET HANDLER go_document_events->on_link FOR go_native_link ACTIVATION space.
    ENDIF.
    IF go_native_button IS BOUND.
      SET HANDLER go_document_events->on_button FOR go_native_button ACTIVATION space.
    ENDIF.
    IF go_native_input IS BOUND.
      SET HANDLER go_document_events->on_entered FOR go_native_input ACTIVATION space.
      SET HANDLER go_document_events->on_help FOR go_native_input ACTIVATION space.
    ENDIF.
    IF go_native_select IS BOUND.
      SET HANDLER go_document_events->on_selected FOR go_native_select ACTIVATION space.
    ENDIF.
  ENDIF.
  FREE: go_document_events, go_native_link, go_native_button,
    go_native_input, go_native_select.
  CLEAR gv_native_events_registered.
  FREE MEMORY ID 'ZGG_GUI_DD_EVENT'.
ENDFORM.
