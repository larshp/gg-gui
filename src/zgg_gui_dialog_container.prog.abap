REPORT zgg_gui_dialog_container.

TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

CONSTANTS c_lifetime_dynpro TYPE i VALUE 1.

DATA go_dialog TYPE REF TO object.
DATA go_container TYPE REF TO cl_gui_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_left TYPE i VALUE 80.
DATA gv_top TYPE i VALUE 60.
DATA gv_width TYPE i VALUE 600.
DATA gv_height TYPE i VALUE 320.
DATA gv_caption TYPE c LENGTH 48 VALUE 'SAP GUI modeless control dialog'.
DATA gv_geometry TYPE c LENGTH 54.
DATA gv_status TYPE c LENGTH 88.
DATA gv_fullscreen TYPE abap_bool.
DATA gv_alternate TYPE abap_bool.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_dialog.
  PERFORM read_geometry.
ENDMODULE.

MODULE dispatch_0100 INPUT.
  DATA lv_return_code TYPE i.

  IF go_container IS BOUND.
    cl_gui_cfw=>dispatch( IMPORTING return_code = lv_return_code ).
    PERFORM detect_frontend_close.
  ENDIF.
ENDMODULE.

MODULE exit_0100 INPUT.
  PERFORM free_dialog.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.

  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_ok_code.
    WHEN 'MOVE'.
      gv_alternate = xsdbool( gv_alternate = abap_false ).
      IF gv_alternate = abap_true.
        gv_left = 220. gv_top = 120.
      ELSE.
        gv_left = 80. gv_top = 60.
      ENDIF.
      PERFORM apply_geometry.
    WHEN 'RESIZE'.
      gv_alternate = xsdbool( gv_alternate = abap_false ).
      IF gv_alternate = abap_true.
        gv_width = 820. gv_height = 480.
      ELSE.
        gv_width = 600. gv_height = 320.
      ENDIF.
      PERFORM apply_geometry.
    WHEN 'FULL'.
      gv_fullscreen = xsdbool( gv_fullscreen = abap_false ).
      PERFORM free_dialog.
      IF gv_fullscreen = abap_true.
        CLEAR: gv_left, gv_top, gv_width, gv_height.
      ELSE.
        gv_left = 80. gv_top = 60. gv_width = 600. gv_height = 320.
      ENDIF.
      PERFORM create_dialog.
    WHEN 'CAPTION'.
      IF gv_caption = 'SAP GUI modeless control dialog'.
        gv_caption = 'Caption changed at runtime'.
      ELSE.
        gv_caption = 'SAP GUI modeless control dialog'.
      ENDIF.
      PERFORM set_caption.
    WHEN 'CLOSE'.
      PERFORM free_dialog.
      gv_status = 'Dialog closed by the owning dynpro; Recreate remains available'.
    WHEN 'RECREATE'.
      PERFORM free_dialog.
      PERFORM create_dialog.
  ENDCASE.
ENDMODULE.

FORM create_dialog.
  DATA lv_class_name TYPE string VALUE 'CL_GUI_DIALOGBOX_CONTAINER'.
  DATA lt_text TYPE ty_text_lines.

  IF go_dialog IS BOUND.
    RETURN.
  ENDIF.
  TRY.
      CREATE OBJECT go_dialog TYPE (lv_class_name)
        EXPORTING
          repid = sy-repid
          dynnr = sy-dynnr
          left = gv_left
          top = gv_top
          width = gv_width
          height = gv_height
          caption = gv_caption
          lifetime = c_lifetime_dynpro.
      go_container ?= go_dialog.
      CREATE OBJECT go_editor EXPORTING parent = go_container.
      lt_text = VALUE #(
        ( 'CL_GUI_DIALOGBOX_CONTAINER' )
        ( 'This is a modeless control window; the owning dynpro remains active.' )
        ( 'Move or resize this window, then use Read geometry on the main screen.' ) ).
      go_editor->set_text_as_r3table( table = lt_text ).
      gv_status = 'Modeless dialog and hosted text editor created'.
    CATCH cx_root INTO DATA(lx_error).
      FREE: go_dialog, go_container, go_editor.
      gv_status = |CL_GUI_DIALOGBOX_CONTAINER unavailable: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM apply_geometry.
  IF go_container IS NOT BOUND.
    gv_status = 'No dialog exists; use Recreate first'.
    RETURN.
  ENDIF.
  go_container->set_position(
    EXPORTING left = gv_left top = gv_top width = gv_width height = gv_height
    EXCEPTIONS cntl_error = 1 cntl_system_error = 2 OTHERS = 3 ).
  gv_status = |Position and size sent to the frontend; rc { sy-subrc }|.
  PERFORM read_geometry.
ENDFORM.

FORM read_geometry.
  DATA lv_width TYPE i.
  DATA lv_height TYPE i.

  IF go_container IS NOT BOUND.
    gv_geometry = 'No modeless dialog is currently bound'.
    RETURN.
  ENDIF.
  go_container->get_width( IMPORTING width = lv_width ).
  go_container->get_height( IMPORTING height = lv_height ).
  gv_geometry = |Requested L{ gv_left } T{ gv_top }; measured { lv_width } x { lv_height }|.
ENDFORM.

FORM set_caption.
  IF go_dialog IS NOT BOUND.
    gv_status = 'No dialog exists; use Recreate first'.
    RETURN.
  ENDIF.
  TRY.
      CALL METHOD go_dialog->('SET_CAPTION')
        EXPORTING caption = gv_caption.
      gv_status = |Dialog caption changed to "{ gv_caption }"|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |SET_CAPTION unavailable: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM detect_frontend_close.
  DATA lv_valid TYPE i.

  go_container->is_valid( IMPORTING result = lv_valid ).
  IF lv_valid = 0.
    FREE: go_editor, go_container, go_dialog.
    gv_status = 'Frontend close detected after CFW dispatch; references were cleared'.
  ENDIF.
ENDFORM.

FORM free_dialog.
  IF go_editor IS BOUND.
    go_editor->free( ).
    FREE go_editor.
  ENDIF.
  IF go_container IS BOUND.
    go_container->free( ).
    FREE go_container.
  ENDIF.
  FREE go_dialog.
ENDFORM.
