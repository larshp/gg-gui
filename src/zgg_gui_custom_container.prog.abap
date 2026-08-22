REPORT zgg_gui_custom_container.

TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

CONSTANTS c_lifetime_default TYPE i VALUE 0.
CONSTANTS c_lifetime_dynpro TYPE i VALUE 1.
CONSTANTS c_lifetime_imode TYPE i VALUE 2.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_lifetime TYPE i VALUE c_lifetime_dynpro.
DATA gv_lifetime_text TYPE c LENGTH 18.
DATA gv_screen0_state TYPE c LENGTH 32.
DATA gv_default_state TYPE c LENGTH 32.
DATA gv_relation TYPE c LENGTH 46.
DATA gv_link_state TYPE c LENGTH 55.
DATA gv_large TYPE abap_bool.
DATA gv_generation TYPE i.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_container.
  PERFORM describe_hosts.
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
    WHEN 'LINK_NAME'.
      go_container->link(
        EXPORTING
          repid                       = sy-repid
          dynnr                       = sy-dynnr
          container                   = 'CC_MAIN'
        EXCEPTIONS
          cntl_error                  = 1
          cntl_system_error           = 2
          lifetime_dynpro_dynpro_link = 3
          OTHERS                      = 4 ).
      gv_link_state = |Linked by program, screen, and custom-control name; rc { sy-subrc }|.
    WHEN 'LIFETIME'.
      CASE gv_lifetime.
        WHEN c_lifetime_default.
          gv_lifetime = c_lifetime_dynpro.
        WHEN c_lifetime_dynpro.
          gv_lifetime = c_lifetime_imode.
        WHEN OTHERS.
          gv_lifetime = c_lifetime_default.
      ENDCASE.
      PERFORM free_controls.
      PERFORM create_container.
      gv_link_state = 'Container recreated with the next lifetime mode'.
    WHEN 'RESIZE'.
      gv_large = xsdbool( gv_large = abap_false ).
      IF gv_large = abap_true.
        go_editor->set_position(
          EXPORTING left = 4
                    top = 4
                    width = 560
                    height = 300
          EXCEPTIONS cntl_error = 1 cntl_system_error = 2 OTHERS = 3 ).
      ELSE.
        go_editor->set_position(
          EXPORTING left = 16
                    top = 12
                    width = 380
                    height = 180
          EXCEPTIONS cntl_error = 1 cntl_system_error = 2 OTHERS = 3 ).
      ENDIF.
      gv_link_state = |Child geometry changed; rc { sy-subrc }|.
    WHEN 'REPLACE'.
      PERFORM free_child.
      PERFORM create_child.
      gv_link_state = |Hosted child replaced; generation { gv_generation }|.
    WHEN 'RESET'.
      PERFORM free_controls.
      gv_lifetime = c_lifetime_dynpro.
      gv_large = abap_false.
      PERFORM create_container.
      gv_link_state = 'Initial custom-container state restored'.
  ENDCASE.
ENDMODULE.

FORM create_container.
  IF go_container IS BOUND.
    RETURN.
  ENDIF.

  CREATE OBJECT go_container
    EXPORTING
      container_name          = 'CC_MAIN'
      repid                   = sy-repid
      dynnr                   = sy-dynnr
      no_autodef_progid_dynnr = abap_true
      lifetime                = gv_lifetime.
  PERFORM create_child.
  gv_link_state = 'Custom container created from explicit dynpro coordinates'.
ENDFORM.

FORM create_child.
  DATA lt_text TYPE ty_text_lines.

  ADD 1 TO gv_generation.
  CREATE OBJECT go_editor
    EXPORTING
      parent = go_container.
  lt_text = VALUE #(
    ( 'CL_GUI_CUSTOM_CONTAINER host' )
    ( |Child generation: { gv_generation }| )
    ( 'Resize this SAP GUI window to exercise the custom-control area.' )
    ( 'Use the buttons below to relink, resize, or replace the child.' ) ).
  go_editor->set_text_as_r3table( lt_text ).
ENDFORM.

FORM describe_hosts.
  CASE gv_lifetime.
    WHEN c_lifetime_default.
      gv_lifetime_text = 'DEFAULT (0)'.
    WHEN c_lifetime_dynpro.
      gv_lifetime_text = 'DYNPRO (1)'.
    WHEN c_lifetime_imode.
      gv_lifetime_text = 'IMODE (2)'.
  ENDCASE.

  gv_screen0_state = COND #( WHEN cl_gui_container=>screen0 IS BOUND
    THEN 'SCREEN0 is bound' ELSE 'SCREEN0 is not bound' ).
  gv_default_state = COND #( WHEN cl_gui_container=>default_screen IS BOUND
    THEN 'DEFAULT_SCREEN is bound' ELSE 'DEFAULT_SCREEN is not bound' ).

  IF cl_gui_container=>screen0 IS BOUND
      AND cl_gui_container=>default_screen IS BOUND
      AND cl_gui_container=>screen0 = cl_gui_container=>default_screen.
    gv_relation = 'SCREEN0 and DEFAULT_SCREEN reference the same host'.
  ELSE.
    gv_relation = 'SCREEN0 and DEFAULT_SCREEN are distinct or unbound'.
  ENDIF.
ENDFORM.

FORM free_child.
  IF go_editor IS BOUND.
    go_editor->free( ).
    FREE go_editor.
  ENDIF.
ENDFORM.

FORM free_controls.
  PERFORM free_child.
  IF go_container IS BOUND.
    go_container->free( ).
    FREE go_container.
  ENDIF.
ENDFORM.
