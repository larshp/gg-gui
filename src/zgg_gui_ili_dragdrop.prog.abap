REPORT zgg_gui_ili_dragdrop.

TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

CLASS lcl_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_dropped FOR EVENT dropped OF cl_gui_ilidragndrop_control
      IMPORTING newleft newtop.
    METHODS on_resized FOR EVENT resized OF cl_gui_ilidragndrop_control
      IMPORTING newwidth newheight.
    METHODS on_menu_request FOR EVENT contextmenu_requested OF cl_gui_ilidragndrop_control.
    METHODS on_menu_click FOR EVENT contextmenu_clicked OF cl_gui_ilidragndrop_control
      IMPORTING no.
ENDCLASS.

DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_ili TYPE REF TO cl_gui_ilidragndrop_control.
DATA go_events TYPE REF TO lcl_events.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_left TYPE i VALUE 20.
DATA gv_top TYPE i VALUE 20.
DATA gv_width TYPE i VALUE 220.
DATA gv_height TYPE i VALUE 120.
DATA gv_visible TYPE abap_bool VALUE abap_true.
DATA gv_menu_count TYPE i.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_dropped.
    gv_left = newleft.
    gv_top = newtop.
    gv_status = |DROPPED event: region moved to left { gv_left }, top { gv_top }|.
  ENDMETHOD.

  METHOD on_resized.
    gv_width = newwidth.
    gv_height = newheight.
    gv_status = |RESIZED event: region size is { gv_width } x { gv_height }|.
  ENDMETHOD.

  METHOD on_menu_request.
    gv_status = 'CONTEXTMENU_REQUESTED: the control internal menu is ready'.
  ENDMETHOD.

  METHOD on_menu_click.
    gv_status = |CONTEXTMENU_CLICKED item { no }|.
    CASE no.
      WHEN 1. PERFORM start_mode USING cl_gui_ilidragndrop_control=>co_drag.
      WHEN 2. PERFORM start_mode USING cl_gui_ilidragndrop_control=>co_resize_xy.
      WHEN 3. PERFORM toggle_visibility.
    ENDCASE.
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
    WHEN 'MOVE'.
      PERFORM start_mode USING cl_gui_ilidragndrop_control=>co_drag.
    WHEN 'RESIZEX'.
      PERFORM start_mode USING cl_gui_ilidragndrop_control=>co_resize_x.
    WHEN 'RESIZEY'.
      PERFORM start_mode USING cl_gui_ilidragndrop_control=>co_resize_y.
    WHEN 'RESIZEXY'.
      PERFORM start_mode USING cl_gui_ilidragndrop_control=>co_drag_resize_xy.
    WHEN 'SHOWHIDE'.
      PERFORM toggle_visibility.
    WHEN 'MENU'.
      PERFORM rebuild_menu.
    WHEN 'CLEAR'.
      PERFORM clear_menu.
    WHEN 'RESET'.
      PERFORM reset_control.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  DATA lv_clsid TYPE string.
  DATA lv_reason TYPE string.

  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  IF go_ili IS BOUND OR go_fallback IS BOUND.
    RETURN.
  ENDIF.
  TRY.
      cl_gui_frontend_services=>registry_get_value(
        EXPORTING root      = 0
                  key       = 'SAPGUI.SAPILIDragNDropCtrl.1\CLSID'
                  value     = space
        IMPORTING reg_value = lv_clsid ).
      cl_gui_cfw=>flush( ).
    CATCH cx_root INTO DATA(lx_registry).
      lv_reason = lx_registry->get_text( ).
      PERFORM show_unavailable USING lv_reason.
      RETURN.
  ENDTRY.
  IF lv_clsid IS INITIAL.
    PERFORM show_unavailable USING 'SAPGUI.SAPILIDragNDropCtrl.1 is not registered on this frontend'.
    RETURN.
  ENDIF.
  PERFORM show_unavailable USING
    'The registered ILI ActiveX control rejects OO Control Framework construction on this frontend'.
ENDFORM.

FORM start_mode USING iv_mode TYPE i.
  IF go_ili IS NOT BOUND.
    gv_status = 'Interactive drag/resize control is unavailable'.
    RETURN.
  ENDIF.
  TRY.
      go_ili->start_dragging(
        left   = gv_left
        top    = gv_top
        width  = gv_width
        height = gv_height
        mode   = iv_mode
        flush  = abap_true ).
      gv_status = |Interactive region started with mode { iv_mode } and current geometry|.
      gv_detail = 'Modes cover move, horizontal resize, vertical resize, and combined move/resize'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Interactive drag/resize start failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM toggle_visibility.
  IF go_ili IS NOT BOUND.
    RETURN.
  ENDIF.
  gv_visible = xsdbool( gv_visible = abap_false ).
  TRY.
      IF gv_visible = abap_true.
        go_ili->show( ).
      ELSE.
        go_ili->hide( ).
      ENDIF.
      gv_status = |Interactive region visibility: { gv_visible }|.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Visibility change failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM rebuild_menu.
  IF go_ili IS NOT BOUND.
    RETURN.
  ENDIF.
  TRY.
      go_ili->clear_contextmenu( ).
      go_ili->add_contextmenuitem( str = 'Move region'
        menumode                       = cl_gui_ilidragndrop_control=>co_mf_enabled ).
      go_ili->add_contextmenuitem( str = 'Resize both axes'
        menumode                       = cl_gui_ilidragndrop_control=>co_mf_enabled ).
      go_ili->add_contextmenuitem( str = ''
        menumode                       = cl_gui_ilidragndrop_control=>co_mf_separator ).
      go_ili->add_contextmenuitem( str = 'Show or hide'
        menumode                       = cl_gui_ilidragndrop_control=>co_mf_checked ).
      go_ili->show_contextmenu( ).
      gv_menu_count = 4.
      gv_status = 'Internal context menu rebuilt with move, resize, separator, and visibility items'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Context menu build/display failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM clear_menu.
  IF go_ili IS NOT BOUND.
    RETURN.
  ENDIF.
  TRY.
      go_ili->hide_contextmenu( ).
      go_ili->clear_contextmenu( ).
      CLEAR gv_menu_count.
      gv_status = 'Internal context menu hidden and cleared'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Context menu clear failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM reset_control.
  gv_left = 20.
  gv_top = 20.
  gv_width = 220.
  gv_height = 120.
  gv_visible = abap_true.
  IF go_ili IS BOUND.
    go_ili->show( ).
    PERFORM rebuild_menu.
    PERFORM start_mode USING cl_gui_ilidragndrop_control=>co_drag_resize_xy.
    gv_status = 'Geometry, visibility, mode, and internal context menu reset'.
  ENDIF.
ENDFORM.

FORM show_fallback USING io_error TYPE REF TO cx_root.
  DATA lv_reason TYPE string.

  lv_reason = io_error->get_text( ).
  PERFORM show_unavailable USING lv_reason.
ENDFORM.

FORM show_unavailable USING iv_error TYPE string.
  DATA lt_text TYPE ty_text_lines.

  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( 'CL_GUI_ILIDRAGNDROP_CONTROL is unavailable or nonfunctional in this runtime.' )
    ( 'The native SAP report retains move/resize modes, geometry, visibility, events, and internal menu calls.' )
    ( 'The legacy ActiveX control is not created when its constructor cannot terminate safely.' ) ).
  go_fallback->set_text_as_r3table( lt_text ).
  go_fallback->set_readonly_mode( 1 ).
  gv_status = 'Interactive drag/resize unavailable; a text fallback is displayed'.
  gv_detail = iv_error.
ENDFORM.

FORM free_controls.
  FREE go_events.
  IF go_ili IS BOUND. go_ili->free( ). FREE go_ili. ENDIF.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
