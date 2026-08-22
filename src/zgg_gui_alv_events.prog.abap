REPORT zgg_gui_alv_events.

TYPES ty_rows TYPE zcl_gg_gui_demo_data=>ty_products.
TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

CLASS lcl_drag_payload DEFINITION FINAL.
  PUBLIC SECTION.
    DATA row_index TYPE i READ-ONLY.
    METHODS constructor IMPORTING iv_row_index TYPE i.
ENDCLASS.

CLASS lcl_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS on_double_click FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column es_row_no.
    METHODS on_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id es_row_no.
    METHODS on_user_command FOR EVENT user_command OF cl_gui_alv_grid
      IMPORTING e_ucomm.
    METHODS on_before_command FOR EVENT before_user_command OF cl_gui_alv_grid
      IMPORTING e_ucomm.
    METHODS on_after_command FOR EVENT after_user_command OF cl_gui_alv_grid
      IMPORTING e_ucomm e_saved e_not_processed.
    METHODS on_f1 FOR EVENT onf1 OF cl_gui_alv_grid
      IMPORTING e_fieldname es_row_no er_event_data.
    METHODS on_f4 FOR EVENT onf4 OF cl_gui_alv_grid
      IMPORTING e_fieldname e_fieldvalue es_row_no er_event_data et_bad_cells e_display.
    METHODS on_button FOR EVENT button_click OF cl_gui_alv_grid
      IMPORTING es_col_id es_row_no.
    METHODS on_menu_button FOR EVENT menu_button OF cl_gui_alv_grid
      IMPORTING e_object e_ucomm.
    METHODS on_subtotal_text FOR EVENT subtotal_text OF cl_gui_alv_grid
      IMPORTING es_subtottxt_info ep_subtot_line e_event_data.
    METHODS on_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
      IMPORTING e_object e_interactive.
    METHODS on_context_menu FOR EVENT context_menu_request OF cl_gui_alv_grid
      IMPORTING e_object.
    METHODS on_drag FOR EVENT ondrag OF cl_gui_alv_grid
      IMPORTING e_row e_column es_row_no e_dragdropobj.
    METHODS on_drop FOR EVENT ondrop OF cl_gui_alv_grid
      IMPORTING e_row e_column es_row_no e_dragdropobj.
    METHODS on_drop_complete FOR EVENT ondropcomplete OF cl_gui_alv_grid
      IMPORTING e_row e_column es_row_no e_dragdropobj.
    METHODS on_drop_flavor FOR EVENT ondropgetflavor OF cl_gui_alv_grid
      IMPORTING e_row e_column es_row_no e_dragdropobj e_flavors.
    METHODS on_top_of_page FOR EVENT top_of_page OF cl_gui_alv_grid
      IMPORTING e_dyndoc_id table_index.
ENDCLASS.

DATA gt_rows TYPE ty_rows.
DATA gt_fieldcat TYPE lvc_t_fcat.
DATA gt_sort TYPE lvc_t_sort.
DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA go_events TYPE REF TO lcl_events.
DATA go_dragdrop TYPE REF TO cl_dragdrop.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_dragdrop_handle TYPE i.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_status TYPE c LENGTH 108.
DATA gv_detail TYPE c LENGTH 108.
DATA gv_event_count TYPE i.
DATA gv_application_events TYPE abap_bool VALUE abap_true.
DATA gv_native_events_registered TYPE abap_bool.
DATA gv_delayed_requested TYPE abap_bool.

INCLUDE zgg_native_alv_events.

CLASS lcl_drag_payload IMPLEMENTATION.
  METHOD constructor.
    row_index = iv_row_index.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_events IMPLEMENTATION.
  METHOD on_double_click.
    ADD 1 TO gv_event_count.
    gv_status = |DOUBLE_CLICK row { e_row-index } / { es_row_no-row_id }, column { e_column-fieldname }|.
  ENDMETHOD.

  METHOD on_hotspot_click.
    ADD 1 TO gv_event_count.
    gv_status = |HOTSPOT_CLICK row { e_row_id-index } / { es_row_no-row_id }, column { e_column_id-fieldname }|.
  ENDMETHOD.

  METHOD on_user_command.
    ADD 1 TO gv_event_count.
    gv_status = |USER_COMMAND { e_ucomm } handled by the sample event receiver|.
  ENDMETHOD.

  METHOD on_before_command.
    ADD 1 TO gv_event_count.
    gv_detail = |BEFORE_USER_COMMAND { e_ucomm } at event sequence { gv_event_count }|.
  ENDMETHOD.

  METHOD on_after_command.
    ADD 1 TO gv_event_count.
    gv_detail = |AFTER_USER_COMMAND { e_ucomm }; saved { e_saved }; not processed { e_not_processed }|.
  ENDMETHOD.

  METHOD on_f1.
    DATA lr_help TYPE REF TO data.
    FIELD-SYMBOLS <help> TYPE string.

    CREATE DATA lr_help TYPE string.
    ASSIGN lr_help->* TO <help>.
    <help> = |Custom F1 help for field { e_fieldname }, row { es_row_no-row_id }|.
    er_event_data->m_data = lr_help.
    er_event_data->m_event_handled = abap_true.
    ADD 1 TO gv_event_count.
    gv_status = <help>.
  ENDMETHOD.

  METHOD on_f4.
    er_event_data->m_event_handled = abap_true.
    ADD 1 TO gv_event_count.
    gv_status = |Custom F4 intercepted for { e_fieldname }, row { es_row_no-row_id }, value { e_fieldvalue }|.
    gv_detail = |Display mode { e_display }; bad-cell context { lines( et_bad_cells ) }|.
  ENDMETHOD.

  METHOD on_button.
    ADD 1 TO gv_event_count.
    gv_status = |BUTTON_CLICK row { es_row_no-row_id }, column { es_col_id-fieldname }|.
  ENDMETHOD.

  METHOD on_menu_button.
    IF e_object IS BOUND.
      e_object->add_function( fcode = 'ZMENU_A' text = 'Menu action A' ).
      e_object->add_function( fcode = 'ZMENU_B' text = 'Menu action B' ).
    ENDIF.
    ADD 1 TO gv_event_count.
    gv_status = |MENU_BUTTON prepared for command { e_ucomm }|.
  ENDMETHOD.

  METHOD on_subtotal_text.
    ADD 1 TO gv_event_count.
    gv_status = |SUBTOTAL_TEXT event received; subtotal row data bound { xsdbool( ep_subtot_line IS BOUND ) }|.
    gv_detail = |Subtotal event-data object bound { xsdbool( e_event_data IS BOUND ) }; source info captured|.
  ENDMETHOD.

  METHOD on_toolbar.
    IF e_object IS BOUND.
      APPEND VALUE #( function = 'ZHELLO' icon = '@0V@'
        quickinfo = 'Raise a custom ALV user command' text = 'Sample action' ) TO e_object->mt_toolbar.
      APPEND VALUE #( function = 'ZMENU' icon = '@3Z@'
        quickinfo = 'Open a custom menu button' text = 'Sample menu' butn_type = 1 ) TO e_object->mt_toolbar.
    ENDIF.
    ADD 1 TO gv_event_count.
    gv_status = |TOOLBAR extended; interactive rebuild flag { e_interactive }|.
  ENDMETHOD.

  METHOD on_context_menu.
    e_object->add_function( fcode = 'ZDETAIL' text = 'Show row details' ).
    e_object->add_separator( ).
    e_object->add_function( fcode = 'ZRESET' text = 'Reset event sample' ).
    ADD 1 TO gv_event_count.
    gv_status = 'CONTEXT_MENU_REQUEST added sample functions and a separator'.
  ENDMETHOD.

  METHOD on_drag.
    CREATE OBJECT e_dragdropobj->object TYPE lcl_drag_payload
      EXPORTING iv_row_index = es_row_no-row_id.
    e_dragdropobj->effect = cl_dragdrop=>move.
    ADD 1 TO gv_event_count.
    gv_status = |ONDRAG row { e_row-index } / { es_row_no-row_id }, column { e_column-fieldname }|.
  ENDMETHOD.

  METHOD on_drop.
    DATA lo_payload TYPE REF TO lcl_drag_payload.

    TRY.
        lo_payload ?= e_dragdropobj->object.
        READ TABLE gt_rows INDEX lo_payload->row_index INTO DATA(ls_row).
        IF sy-subrc = 0.
          DELETE gt_rows INDEX lo_payload->row_index.
          INSERT ls_row INTO gt_rows INDEX es_row_no-row_id.
          go_grid->refresh_table_display(
            is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
          gv_status = |ONDROP moved source row { lo_payload->row_index } to target row { es_row_no-row_id }|.
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        e_dragdropobj->abort( ).
        gv_status = |Drop aborted: { lx_error->get_text( ) }|.
    ENDTRY.
    ADD 1 TO gv_event_count.
    gv_detail = |Drop target column { e_column-fieldname }; displayed index { e_row-index }|.
  ENDMETHOD.

  METHOD on_drop_complete.
    ADD 1 TO gv_event_count.
    gv_status = |ONDROPCOMPLETE row { e_row-index } / { es_row_no-row_id }, column { e_column-fieldname }|.
    gv_detail = |Drag/drop state { e_dragdropobj->state }, effect { e_dragdropobj->effect }|.
  ENDMETHOD.

  METHOD on_drop_flavor.
    ADD 1 TO gv_event_count.
    gv_status = |ONDROPGETFLAVOR row { e_row-index } / { es_row_no-row_id }, flavor { concat_lines_of( table = e_flavors sep = ',' ) }|.
    gv_detail = |Column { e_column-fieldname }; drag object bound { xsdbool( e_dragdropobj IS BOUND ) }|.
  ENDMETHOD.

  METHOD on_top_of_page.
    ADD 1 TO gv_event_count.
    IF e_dyndoc_id IS BOUND.
      e_dyndoc_id->add_text( text = |ALV event sample - print table { table_index }| ).
    ENDIF.
    gv_status = |TOP_OF_PAGE event for table index { table_index }|.
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

MODULE dispatch_0100 INPUT.
  DATA lv_return_code TYPE i.

  IF go_grid IS BOUND AND gv_application_events = abap_true.
    cl_gui_cfw=>dispatch( IMPORTING return_code = lv_return_code ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.

  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_ok_code.
    WHEN 'CUSTOM'.
      PERFORM raise_custom_command.
    WHEN 'TOOLBAR'.
      PERFORM rebuild_toolbar.
    WHEN 'DELAYED'.
      PERFORM register_delayed.
    WHEN 'PRINT'.
      PERFORM request_print_events.
    WHEN 'MODE'.
      PERFORM toggle_event_mode.
    WHEN 'RESET'.
      PERFORM reset_sample.
    WHEN 'ALV_DELAYED'.
      FREE MEMORY ID 'ZGG_GUI_ALV_DELAYED'.
      ADD 1 TO gv_event_count.
      gv_status = |DELAYED_CHANGED_SEL_CALLBACK received; event sequence { gv_event_count }|.
      gv_detail = 'Selection stabilized before the delayed native callback reached the application'.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  IF go_host IS NOT BOUND.
    CREATE OBJECT go_host EXPORTING container_name = 'CC_MAIN'.
  ENDIF.
  IF go_grid IS BOUND OR go_fallback IS BOUND.
    RETURN.
  ENDIF.
  gt_rows = zcl_gg_gui_demo_data=>products( ).
  PERFORM build_catalog.
  PERFORM configure_dragdrop.
  PERFORM create_grid.
ENDFORM.

FORM build_catalog.
  gt_fieldcat = VALUE #(
    ( fieldname = 'ID' col_pos = 1 coltext = 'Product ID' key = abap_true
      hotspot = abap_true outputlen = 10 dragdropid = gv_dragdrop_handle )
    ( fieldname = 'NAME' col_pos = 2 coltext = 'Product name' f4availabl = abap_true
      outputlen = 30 dragdropid = gv_dragdrop_handle )
    ( fieldname = 'CATEGORY' col_pos = 3 coltext = 'Category' outputlen = 20
      dragdropid = gv_dragdrop_handle )
    ( fieldname = 'QUANTITY' col_pos = 4 coltext = 'Quantity' do_sum = abap_true
      outputlen = 10 dragdropid = gv_dragdrop_handle )
    ( fieldname = 'PRICE' col_pos = 5 coltext = 'Price' cfieldname = 'CURRENCY'
      do_sum = abap_true outputlen = 14 dragdropid = gv_dragdrop_handle )
    ( fieldname = 'CURRENCY' col_pos = 6 coltext = 'Currency' outputlen = 8
      dragdropid = gv_dragdrop_handle ) ).
  gt_sort = VALUE #( ( spos = 1 fieldname = 'CATEGORY' up = abap_true subtot = abap_true ) ).
ENDFORM.

FORM configure_dragdrop.
  TRY.
      CREATE OBJECT go_dragdrop.
      go_dragdrop->add(
        flavor = 'GG_ROWS' dragsrc = abap_true droptarget = abap_true
        effect = cl_dragdrop=>move effect_in_ctrl = cl_dragdrop=>move ).
      go_dragdrop->get_handle( IMPORTING handle = gv_dragdrop_handle ).
    CATCH cx_root INTO DATA(lx_error).
      CLEAR gv_dragdrop_handle.
      gv_detail = |Drag/drop setup unavailable: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM create_grid.
  DATA lv_appl_events TYPE char1.

  lv_appl_events = COND #( WHEN gv_application_events = abap_true THEN abap_true ELSE space ).
  TRY.
      CREATE OBJECT go_grid
        EXPORTING i_parent = go_host i_appl_events = lv_appl_events.
      CREATE OBJECT go_events.
      SET HANDLER go_events->on_double_click FOR go_grid.
      SET HANDLER go_events->on_hotspot_click FOR go_grid.
      SET HANDLER go_events->on_user_command FOR go_grid.
      SET HANDLER go_events->on_before_command FOR go_grid.
      SET HANDLER go_events->on_after_command FOR go_grid.
      SET HANDLER go_events->on_f1 FOR go_grid.
      SET HANDLER go_events->on_f4 FOR go_grid.
      SET HANDLER go_events->on_button FOR go_grid.
      SET HANDLER go_events->on_menu_button FOR go_grid.
      SET HANDLER go_events->on_subtotal_text FOR go_grid.
      SET HANDLER go_events->on_toolbar FOR go_grid.
      SET HANDLER go_events->on_context_menu FOR go_grid.
      SET HANDLER go_events->on_drag FOR go_grid.
      SET HANDLER go_events->on_drop FOR go_grid.
      SET HANDLER go_events->on_drop_complete FOR go_grid.
      SET HANDLER go_events->on_drop_flavor FOR go_grid.
      SET HANDLER go_events->on_top_of_page FOR go_grid.
      go_grid->register_f4_for_fields( VALUE lvc_t_f4(
        ( fieldname = 'NAME' register = abap_true getbefore = abap_true ) ) ).
      go_grid->set_table_for_first_display(
        EXPORTING is_layout = VALUE lvc_s_layo(
          zebra = abap_true cwidth_opt = abap_true sel_mode = 'A'
          grid_title = 'ALV event and extension gallery' )
          is_print = VALUE lvc_s_prnt( print = abap_true prnt_title = abap_true )
        CHANGING it_outtab = gt_rows it_fieldcatalog = gt_fieldcat it_sort = gt_sort ).
      go_grid->set_toolbar_interactive( ).
      gv_status = |ALV event handlers registered; application-event mode { gv_application_events }|.
      gv_detail = |Drag/drop handle { gv_dragdrop_handle }; use grid interactions or the explicit event buttons below|.
      IF gv_delayed_requested = abap_true.
        PERFORM register_native_delayed_event.
      ENDIF.
    CATCH cx_root INTO DATA(lx_error).
      FREE: go_grid, go_events.
      PERFORM show_fallback USING lx_error.
  ENDTRY.
ENDFORM.

FORM raise_custom_command.
  IF go_grid IS NOT BOUND.
    RETURN.
  ENDIF.
  TRY.
      go_grid->raise_event( i_ucomm = 'ZHELLO' i_user_command = abap_true ).
      go_grid->set_user_command( 'ZHELLO' ).
      gv_status = 'Custom ZHELLO command raised through the ALV event and user-command paths'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Custom command failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM rebuild_toolbar.
  IF go_grid IS NOT BOUND.
    RETURN.
  ENDIF.
  TRY.
      go_grid->set_toolbar_interactive( ).
      gv_status = 'Interactive toolbar rebuild requested; TOOLBAR adds an action and menu button'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Toolbar rebuild failed: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM register_delayed.
  IF go_grid IS NOT BOUND.
    RETURN.
  ENDIF.
  gv_delayed_requested = abap_true.
  PERFORM register_native_delayed_event.
  IF gv_native_events_registered = abap_true.
    gv_status = 'Delayed selection-change event ID and native callback registered'.
    gv_detail = 'Change the selected cells, rows, or columns and wait for the delayed callback'.
  ENDIF.
ENDFORM.

FORM request_print_events.
  IF go_grid IS NOT BOUND.
    RETURN.
  ENDIF.
  TRY.
      go_grid->list_processing_events( i_event_name = 'TOP_OF_PAGE' i_table_index = 1 ).
      go_grid->set_user_command( '&PRINT' ).
      gv_status = 'TOP_OF_PAGE list processing and the standard print command were requested'.
    CATCH cx_root INTO DATA(lx_error).
      gv_status = |Print event request failed or was canceled: { lx_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM toggle_event_mode.
  gv_application_events = xsdbool( gv_application_events = abap_false ).
  PERFORM unregister_delayed_event.
  IF go_grid IS BOUND. go_grid->free( ). FREE go_grid. ENDIF.
  FREE go_events.
  PERFORM create_grid.
  gv_status = |Grid recreated with application-event mode { gv_application_events }|.
  gv_detail = COND #( WHEN gv_application_events = abap_true
    THEN 'Application events are dispatched through PAI/CFW processing'
    ELSE 'System events are delivered immediately by the Control Framework' ).
ENDFORM.

FORM reset_sample.
  gt_rows = zcl_gg_gui_demo_data=>products( ).
  CLEAR gv_event_count.
  IF go_grid IS BOUND.
    TRY.
        go_grid->refresh_table_display(
          is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
        gv_status = 'Rows and event sequence reset; handler registrations and current event mode remain active'.
      CATCH cx_root INTO DATA(lx_error).
        gv_status = |Event sample reset failed: { lx_error->get_text( ) }|.
    ENDTRY.
  ENDIF.
ENDFORM.

FORM show_fallback USING io_error TYPE REF TO cx_root.
  DATA lt_text TYPE ty_text_lines.

  CREATE OBJECT go_fallback EXPORTING parent = go_host.
  lt_text = VALUE #(
    ( 'CL_GUI_ALV_GRID event behavior is unavailable in this runtime.' )
    ( 'The native SAP report retains its handlers, toolbar/context extensions, drag/drop, and print hooks.' )
    ( 'The delayed-selection callback is missing from the pinned open-abap class definition.' ) ).
  go_fallback->set_text_as_r3table( lt_text ).
  go_fallback->set_readonly_mode( 1 ).
  gv_status = 'ALV events unavailable; a non-terminating text fallback is displayed'.
  gv_detail = io_error->get_text( ).
ENDFORM.

FORM free_controls.
  PERFORM unregister_delayed_event.
  FREE: go_events, go_dragdrop.
  IF go_grid IS BOUND. go_grid->free( ). FREE go_grid. ENDIF.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
