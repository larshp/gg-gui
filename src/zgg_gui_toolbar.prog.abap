REPORT zgg_gui_toolbar.

CONSTANTS c_button TYPE i VALUE 0.
CONSTANTS c_check TYPE i VALUE 1.
CONSTANTS c_separator TYPE i VALUE 3.
CONSTANTS c_dropdown TYPE i VALUE 4.
CONSTANTS c_menu TYPE i VALUE 5.

CLASS lcl_events DEFINITION.
  PUBLIC SECTION.
    METHODS on_function FOR EVENT function_selected OF cl_gui_toolbar
      IMPORTING fcode.
    METHODS on_dropdown FOR EVENT dropdown_clicked OF cl_gui_toolbar
      IMPORTING fcode posx posy.
ENDCLASS.

DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_toolbar TYPE REF TO cl_gui_toolbar.
DATA go_events TYPE REF TO lcl_events.
DATA go_menu TYPE REF TO cl_ctmenu.
DATA go_submenu TYPE REF TO cl_ctmenu.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_vertical TYPE abap_bool.
DATA gv_enabled TYPE abap_bool VALUE abap_true.
DATA gv_checked TYPE abap_bool.
DATA gv_visible TYPE abap_bool VALUE abap_true.
DATA gv_dynamic_added TYPE abap_bool.
DATA gv_status TYPE c LENGTH 108.
DATA gv_event TYPE c LENGTH 108.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_function.
    gv_event = |FUNCTION_SELECTED: { fcode }|.
    cl_gui_cfw=>set_new_ok_code( 'TOOL_EVENT' ).
  ENDMETHOD.

  METHOD on_dropdown.
    gv_event = |DROPDOWN_CLICKED: { fcode } at { posx },{ posy }|.
    go_toolbar->track_context_menu(
      EXPORTING context_menu = go_menu posx = posx posy = posy
      EXCEPTIONS ctmenu_error = 1 OTHERS = 2 ).
    cl_gui_cfw=>set_new_ok_code( 'TOOL_EVENT' ).
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  PERFORM create_controls.
ENDMODULE.

MODULE dispatch_0100 INPUT.
  DATA lv_return_code TYPE i.
  cl_gui_cfw=>dispatch( IMPORTING return_code = lv_return_code ).
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
    WHEN 'ADD'.
      IF gv_dynamic_added = abap_false.
        go_toolbar->add_button(
          fcode = 'DYNAMIC' icon = '@17@' butn_type = c_button
          text = 'Dynamic' quickinfo = 'Added after initial creation' ).
        gv_dynamic_added = abap_true.
        gv_status = 'Dynamic button appended'.
      ENDIF.
    WHEN 'DELETE'.
      go_toolbar->delete_button(
        EXPORTING fcode = 'DYNAMIC'
        EXCEPTIONS cntl_error = 1 cntb_error_fcode = 2 OTHERS = 3 ).
      gv_dynamic_added = abap_false.
      gv_status = |Dynamic button deleted; rc { sy-subrc }|.
    WHEN 'STATE'.
      gv_enabled = xsdbool( gv_enabled = abap_false ).
      gv_checked = xsdbool( gv_checked = abap_false ).
      go_toolbar->set_button_state(
        EXPORTING fcode = 'TOGGLE' enabled = gv_enabled checked = gv_checked
        EXCEPTIONS cntl_error = 1 cntb_error_fcode = 2 OTHERS = 3 ).
      gv_status = |Toggle enabled={ gv_enabled }, checked={ gv_checked }; rc { sy-subrc }|.
    WHEN 'VISIBLE'.
      gv_visible = xsdbool( gv_visible = abap_false ).
      go_toolbar->set_button_visible(
        EXPORTING fcode = 'NORMAL' visible = gv_visible
        EXCEPTIONS cntl_error = 1 cntb_error_fcode = 2 OTHERS = 3 ).
      gv_status = |Normal button visible={ gv_visible }; rc { sy-subrc }|.
    WHEN 'INFO'.
      go_toolbar->set_button_info(
        fcode = 'NORMAL' icon = '@42@' text = 'Changed'
        quickinfo = 'Text and quick info changed' ).
      gv_status = 'Normal button icon, text, and quick info changed'.
    WHEN 'GROUP'.
      PERFORM add_button_group.
    WHEN 'ORIENT'.
      gv_vertical = xsdbool( gv_vertical = abap_false ).
      PERFORM free_toolbar.
      PERFORM create_toolbar.
      gv_status = |Toolbar rebuilt; vertical mode={ gv_vertical }|.
    WHEN 'RESET'.
      gv_enabled = abap_true.
      gv_checked = abap_false.
      gv_visible = abap_true.
      gv_vertical = abap_false.
      CLEAR gv_event.
      PERFORM free_toolbar.
      PERFORM create_toolbar.
      gv_status = 'Toolbar buttons, states, visibility, groups, and orientation reset'.
    WHEN 'TOOL_EVENT'.
      gv_status = 'Toolbar control event dispatched to ABAP'.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  IF go_host IS BOUND.
    RETURN.
  ENDIF.

  CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  CREATE OBJECT go_events.
  PERFORM create_menus.
  PERFORM create_toolbar.
ENDFORM.

FORM create_menus.
  CREATE OBJECT go_menu.
  CREATE OBJECT go_submenu.
  go_menu->add_function( fcode = 'MENU_ONE' text = 'First action' icon = '@0V@' ).
  go_menu->add_separator( ).
  go_submenu->add_function( fcode = 'SUB_ONE' text = 'Nested action' ).
  go_submenu->add_function(
    fcode = 'SUB_DISABLED' text = 'Disabled action' disabled = abap_true ).
  go_menu->add_submenu( menu = go_submenu text = 'More actions' ).
ENDFORM.

FORM create_toolbar.
  DATA lt_events TYPE cntl_simple_events.
  DATA lt_static_menus TYPE ttb_btnmnu.

  CREATE OBJECT go_toolbar
    EXPORTING
      parent       = go_host
      display_mode = COND #( WHEN gv_vertical = abap_true
        THEN cl_gui_toolbar=>m_mode_vertical
        ELSE cl_gui_toolbar=>m_mode_horizontal ).
  SET HANDLER go_events->on_function FOR go_toolbar.
  SET HANDLER go_events->on_dropdown FOR go_toolbar.

  lt_events = VALUE #(
    ( eventid = cl_gui_toolbar=>m_id_function_selected appl_event = abap_true )
    ( eventid = cl_gui_toolbar=>m_id_dropdown_clicked appl_event = abap_true ) ).
  go_toolbar->set_registered_events( lt_events ).

  go_toolbar->add_button(
    fcode = 'NORMAL' icon = '@42@' butn_type = c_button
    text = 'Normal' quickinfo = 'Normal toolbar button' ).
  go_toolbar->add_button(
    fcode = 'TOGGLE' icon = '@0V@' butn_type = c_check
    text = 'Toggle' quickinfo = 'Check or toggle button' ).
  go_toolbar->add_button( fcode = '' icon = '' butn_type = c_separator ).
  go_toolbar->add_button(
    fcode = 'DROPDOWN' icon = '@0S@' butn_type = c_dropdown
    text = 'Dropdown' quickinfo = 'Raises DROPDOWN_CLICKED' ).
  go_toolbar->add_button(
    fcode = 'MENU' icon = '@3S@' butn_type = c_menu
    text = 'Menu' quickinfo = 'Open static context menu' ).
  go_toolbar->add_button(
    fcode = 'DISABLED' icon = '@0W@' butn_type = c_button
    text = 'Disabled' quickinfo = 'Initially disabled button'
    is_disabled = abap_true ).

  lt_static_menus = VALUE #( ( function = 'MENU' ctmenu = go_menu ) ).
  go_toolbar->assign_static_ctxmenu_table( lt_static_menus ).
  gv_dynamic_added = abap_false.
  gv_status = 'Toolbar buttons, events, and static/dynamic context menus created'.
ENDFORM.

FORM add_button_group.
  DATA lt_buttons TYPE ttb_button.

  cl_gui_toolbar=>fill_buttons_data_table(
    EXPORTING fcode = 'GROUP_A' icon = '@0V@' butn_type = '0'
      text = 'Group A' quickinfo = 'First grouped button'
    CHANGING data_table = lt_buttons ).
  cl_gui_toolbar=>fill_buttons_data_table(
    EXPORTING fcode = 'GROUP_B' icon = '@0W@' butn_type = '0'
      text = 'Group B' quickinfo = 'Second grouped button'
    CHANGING data_table = lt_buttons ).
  go_toolbar->add_button_group( lt_buttons ).
  gv_status = 'Two buttons added with ADD_BUTTON_GROUP'.
ENDFORM.

FORM free_toolbar.
  IF go_toolbar IS BOUND. go_toolbar->free( ). FREE go_toolbar. ENDIF.
ENDFORM.

FORM free_controls.
  PERFORM free_toolbar.
  FREE: go_menu, go_submenu, go_events.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
