REPORT zgg_gui_docking_container.

TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

CONSTANTS c_dock_left TYPE i VALUE 1.
CONSTANTS c_dock_right TYPE i VALUE 2.
CONSTANTS c_dock_top TYPE i VALUE 4.
CONSTANTS c_dock_bottom TYPE i VALUE 8.
CONSTANTS c_lifetime_dynpro TYPE i VALUE 1.

DATA go_docking TYPE REF TO object.
DATA go_container TYPE REF TO cl_gui_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_side TYPE i VALUE c_dock_left.
DATA gv_extension TYPE i VALUE 260.
DATA gv_side_text TYPE c LENGTH 18.
DATA gv_geometry TYPE c LENGTH 42.
DATA gv_status TYPE c LENGTH 86.
DATA gv_last_width TYPE i.
DATA gv_last_height TYPE i.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_controls.
  PERFORM observe_geometry.
ENDMODULE.

MODULE dispatch_0100 INPUT.
  DATA lv_return_code TYPE i.

  IF go_container IS BOUND.
    cl_gui_cfw=>dispatch( IMPORTING return_code = lv_return_code ).
    PERFORM detect_close.
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
  IF go_docking IS NOT BOUND AND lv_ok_code <> 'RECREATE'.
    gv_status = 'Docking class unavailable; use Recreate after installing the native class'.
    RETURN.
  ENDIF.

  CASE lv_ok_code.
    WHEN 'SIDE'.
      CASE gv_side.
        WHEN c_dock_left. gv_side = c_dock_top.
        WHEN c_dock_top. gv_side = c_dock_right.
        WHEN c_dock_right. gv_side = c_dock_bottom.
        WHEN OTHERS. gv_side = c_dock_left.
      ENDCASE.
      PERFORM dock_at_side.
    WHEN 'EXTEND_UP'.
      gv_extension = gv_extension + 40.
      PERFORM set_extension.
    WHEN 'EXTEND_DOWN'.
      gv_extension = nmax( val1 = 80
                           val2 = gv_extension - 40 ).
      PERFORM set_extension.
    WHEN 'FLOAT'.
      PERFORM optional_docking_method USING 'DETACH'.
    WHEN 'ATTACH'.
      PERFORM optional_docking_method USING 'ATTACH'.
      PERFORM dock_at_side.
    WHEN 'RELINK'.
      go_container->link(
        EXPORTING repid = sy-repid
                  dynnr = sy-dynnr
        EXCEPTIONS cntl_error = 1 cntl_system_error = 2
          lifetime_dynpro_dynpro_link = 3 OTHERS = 4 ).
      gv_status = |Relinked to the current dynpro; rc { sy-subrc }|.
    WHEN 'RECREATE'.
      PERFORM free_controls.
      PERFORM create_controls.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  DATA lv_class_name TYPE string VALUE 'CL_GUI_DOCKING_CONTAINER'.
  DATA lt_text TYPE ty_text_lines.

  IF go_docking IS BOUND.
    RETURN.
  ENDIF.

  TRY.
      CREATE OBJECT go_docking TYPE (lv_class_name)
        EXPORTING
          repid                   = sy-repid
          dynnr                   = sy-dynnr
          side                    = gv_side
          extension               = gv_extension
          lifetime                = c_lifetime_dynpro
          no_autodef_progid_dynnr = abap_true.
      go_container ?= go_docking.
      CREATE OBJECT go_editor EXPORTING parent = go_container.
      lt_text = VALUE #(
        ( 'CL_GUI_DOCKING_CONTAINER' )
        ( 'Drag the docking grip to resize or float it where the frontend supports this.' )
        ( 'Use the dynpro buttons to change edge and extension.' ) ).
      go_editor->set_text_as_r3table( lt_text ).
      gv_status = 'Docking container created and linked to the current dynpro'.
    CATCH cx_root INTO DATA(lx_error).
      FREE go_docking.
      FREE go_container.
      gv_status = |CL_GUI_DOCKING_CONTAINER unavailable: { lx_error->get_text( ) }|.
  ENDTRY.
  PERFORM describe_side.
ENDFORM.

FORM dock_at_side.
  TRY.
      CALL METHOD go_docking->('DOCK_AT')
        EXPORTING side = gv_side.
      PERFORM describe_side.
      gv_status = |Docked at { gv_side_text }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |DOCK_AT failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM set_extension.
  TRY.
      CALL METHOD go_docking->('SET_EXTENSION')
        EXPORTING extension = gv_extension.
      gv_status = |Docking extension set to { gv_extension }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |SET_EXTENSION failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM optional_docking_method USING iv_method TYPE c.
  TRY.
      CALL METHOD go_docking->(iv_method).
      gv_status = |Optional docking method { iv_method } executed|.
    CATCH cx_root.
      gv_status = |{ iv_method } is not exposed; use the frontend docking grip|.
  ENDTRY.
ENDFORM.

FORM observe_geometry.
  DATA lv_width TYPE i.
  DATA lv_height TYPE i.

  IF go_container IS NOT BOUND.
    gv_geometry = 'No docking-container geometry available'.
    RETURN.
  ENDIF.
  go_container->get_width( IMPORTING width = lv_width ).
  go_container->get_height( IMPORTING height = lv_height ).
  gv_geometry = |Measured { lv_width } x { lv_height }; extension { gv_extension }|.
  IF gv_last_width <> 0
      AND ( gv_last_width <> lv_width OR gv_last_height <> lv_height ).
    gv_status = |Resize observed: { gv_last_width }x{ gv_last_height } -> { lv_width }x{ lv_height }|.
  ENDIF.
  gv_last_width = lv_width.
  gv_last_height = lv_height.
ENDFORM.

FORM detect_close.
  DATA lv_valid TYPE i.

  go_container->is_valid( IMPORTING result = lv_valid ).
  IF lv_valid = 0.
    FREE go_editor.
    FREE go_container.
    FREE go_docking.
    gv_status = 'Close event observed: frontend container reference is no longer valid'.
  ENDIF.
ENDFORM.

FORM describe_side.
  CASE gv_side.
    WHEN c_dock_left. gv_side_text = 'LEFT (1)'.
    WHEN c_dock_right. gv_side_text = 'RIGHT (2)'.
    WHEN c_dock_top. gv_side_text = 'TOP (4)'.
    WHEN c_dock_bottom. gv_side_text = 'BOTTOM (8)'.
  ENDCASE.
ENDFORM.

FORM free_controls.
  IF go_editor IS BOUND.
    go_editor->free( ).
    FREE go_editor.
  ENDIF.
  IF go_container IS BOUND.
    go_container->free( ).
    FREE go_container.
  ENDIF.
  FREE go_docking.
  CLEAR: gv_last_width, gv_last_height.
ENDFORM.
