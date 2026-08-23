REPORT zgg_gui_splitter_container.

TYPES ty_text_line TYPE c LENGTH 255.
TYPES ty_text_lines TYPE STANDARD TABLE OF ty_text_line WITH EMPTY KEY.

DATA go_host TYPE REF TO cl_gui_custom_container.
DATA go_splitter TYPE REF TO cl_gui_splitter_container.
DATA go_nested TYPE REF TO cl_gui_splitter_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA go_html TYPE REF TO cl_gui_html_viewer.
DATA go_nested_left TYPE REF TO cl_gui_textedit.
DATA go_nested_right TYPE REF TO cl_gui_textedit.
DATA go_easy TYPE REF TO cl_gui_easy_splitter_container.
DATA go_easy_left TYPE REF TO cl_gui_textedit.
DATA go_easy_right TYPE REF TO cl_gui_textedit.
DATA go_fallback TYPE REF TO cl_gui_textedit.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_relative TYPE abap_bool VALUE abap_true.
DATA gv_sashes TYPE abap_bool VALUE abap_true.
DATA gv_border TYPE abap_bool VALUE abap_true.
DATA gv_hidden TYPE abap_bool.
DATA gv_status TYPE c LENGTH 110.

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
  DATA lv_row_rc TYPE i.
  DATA lv_col_rc TYPE i.
  DATA lv_hide_rc TYPE i.

  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  CASE lv_ok_code.
    WHEN 'MODE'.
      gv_relative = xsdbool( gv_relative = abap_false ).
      PERFORM apply_sizes.
    WHEN 'SIZE'.
      IF gv_relative = abap_true.
        go_splitter->set_row_height(
          EXPORTING id     = 1
                    height = 35
          IMPORTING result = lv_row_rc ).
        go_splitter->set_column_width(
          EXPORTING id     = 1
                    width  = 30
          IMPORTING result = lv_col_rc ).
      ELSE.
        go_splitter->set_row_height(
          EXPORTING id     = 1
                    height = 180
          IMPORTING result = lv_row_rc ).
        go_splitter->set_column_width(
          EXPORTING id     = 1
                    width  = 320
          IMPORTING result = lv_col_rc ).
      ENDIF.
      PERFORM set_minimum_sizes.
      cl_gui_cfw=>flush( ).
      gv_status = |Sizes changed; row rc { lv_row_rc }, column rc { lv_col_rc }|.
    WHEN 'SASH'.
      gv_sashes = xsdbool( gv_sashes = abap_false ).
      PERFORM apply_sashes.
    WHEN 'HIDE'.
      gv_hidden = xsdbool( gv_hidden = abap_false ).
      IF gv_hidden = abap_true.
        go_splitter->set_row_height(
          EXPORTING id     = 2
                    height = 0
          IMPORTING result = lv_hide_rc ).
        cl_gui_cfw=>flush( ).
        gv_status = |Lower row hidden; rc { lv_hide_rc }|.
      ELSE.
        PERFORM apply_sizes.
      ENDIF.
    WHEN 'BORDER'.
      gv_border = xsdbool( gv_border = abap_false ).
      go_splitter->set_border( gv_border ).
      go_nested->set_border( gv_border ).
      gv_status = |Outer and nested borders enabled: { gv_border }|.
    WHEN 'READ'.
      PERFORM read_sizes.
    WHEN 'REBUILD'.
      PERFORM free_controls.
      PERFORM create_controls.
      gv_status = 'The complete nested container hierarchy was rebuilt'.
  ENDCASE.
ENDMODULE.

FORM create_controls.
  DATA lo_top_left TYPE REF TO cl_gui_container.
  DATA lo_top_right TYPE REF TO cl_gui_container.
  DATA lo_bottom_left TYPE REF TO cl_gui_container.
  DATA lo_bottom_right TYPE REF TO cl_gui_container.

  IF go_host IS BOUND.
    RETURN.
  ENDIF.

  CREATE OBJECT go_host
    EXPORTING container_name = 'CC_MAIN'.
  CREATE OBJECT go_splitter
    EXPORTING parent  = go_host
              rows    = 2
              columns = 2.

  lo_top_left = go_splitter->get_container( row    = 1
                                            column = 1 ).
  lo_top_right = go_splitter->get_container( row    = 1
                                             column = 2 ).
  lo_bottom_left = go_splitter->get_container( row    = 2
                                               column = 1 ).
  lo_bottom_right = go_splitter->get_container( row    = 2
                                                column = 2 ).

  PERFORM create_editor USING lo_top_left 'Editable text control'.
  CREATE OBJECT go_html
    EXPORTING parent = lo_top_right.
  PERFORM load_html.

  CREATE OBJECT go_nested
    EXPORTING parent  = lo_bottom_left
              rows    = 1
              columns = 2.
  PERFORM create_nested_editors.
  PERFORM create_easy_splitter USING lo_bottom_right.

  PERFORM apply_sizes.
  PERFORM apply_sashes.
  go_splitter->set_border( gv_border ).
  go_nested->set_border( gv_border ).
  gv_status = 'Standard 2x2 splitter, nested splitter, and easy-splitter comparison created'.
ENDFORM.

FORM create_editor USING io_parent TYPE REF TO cl_gui_container
                         iv_title TYPE c.
  DATA lt_text TYPE ty_text_lines.

  CREATE OBJECT go_editor
    EXPORTING parent = io_parent.
  lt_text = VALUE #(
    ( iv_title )
    ( 'This cell contains an editable CL_GUI_TEXTEDIT instance.' ) ).
  go_editor->set_text_as_r3table( lt_text ).
ENDFORM.

FORM load_html.
  DATA lt_html TYPE ty_text_lines.
  DATA lv_url TYPE c LENGTH 255.

  lt_html = VALUE #(
    ( '<html><body style="font-family:sans-serif;background:#f4f6f7;padding:12px">' )
    ( '<h3>HTML viewer cell</h3>' )
    ( '<p>This document was loaded from an ABAP internal table.</p>' )
    ( '</body></html>' ) ).
  go_html->load_data(
    IMPORTING assigned_url = lv_url
    CHANGING data_table    = lt_html ).
  go_html->show_url( url      = lv_url
                     in_place = abap_true ).
ENDFORM.

FORM create_nested_editors.
  DATA lt_text TYPE ty_text_lines.
  DATA lo_left TYPE REF TO cl_gui_container.
  DATA lo_right TYPE REF TO cl_gui_container.

  lo_left = go_nested->get_container( row    = 1
                                      column = 1 ).
  lo_right = go_nested->get_container( row    = 1
                                       column = 2 ).
  CREATE OBJECT go_nested_left EXPORTING parent = lo_left.
  CREATE OBJECT go_nested_right EXPORTING parent = lo_right.
  lt_text = VALUE #( ( 'Nested left cell' ) ).
  go_nested_left->set_text_as_r3table( lt_text ).
  lt_text = VALUE #( ( 'Nested right cell' ) ).
  go_nested_right->set_text_as_r3table( lt_text ).
ENDFORM.

FORM create_easy_splitter USING io_parent TYPE REF TO cl_gui_container.
  DATA lt_text TYPE ty_text_lines.

  TRY.
      CREATE OBJECT go_easy
        EXPORTING parent      = io_parent
                  orientation = cl_gui_easy_splitter_container=>orientation_horizontal.
      IF go_easy->top_left_container IS BOUND.
        CREATE OBJECT go_easy_left EXPORTING parent = go_easy->top_left_container.
        lt_text = VALUE #( ( 'Easy splitter: top/left' ) ).
        go_easy_left->set_text_as_r3table( lt_text ).
      ENDIF.
      IF go_easy->bottom_right_container IS BOUND.
        CREATE OBJECT go_easy_right EXPORTING parent = go_easy->bottom_right_container.
        lt_text = VALUE #( ( 'Easy splitter: bottom/right' ) ).
        go_easy_right->set_text_as_r3table( lt_text ).
      ENDIF.
    CATCH cx_root.
      CREATE OBJECT go_fallback EXPORTING parent = io_parent.
      lt_text = VALUE #(
        ( 'CL_GUI_EASY_SPLITTER_CONTAINER is unavailable.' )
        ( 'The standard splitter remains fully usable.' ) ).
      go_fallback->set_text_as_r3table( lt_text ).
  ENDTRY.
ENDFORM.

FORM apply_sizes.
  DATA lv_row_rc TYPE i.
  DATA lv_col_rc TYPE i.

  IF gv_relative = abap_true.
    go_splitter->set_row_mode(
      EXPORTING mode   = cl_gui_splitter_container=>mode_relative
      IMPORTING result = lv_row_rc ).
    go_splitter->set_column_mode(
      EXPORTING mode   = cl_gui_splitter_container=>mode_relative
      IMPORTING result = lv_col_rc ).
    go_splitter->set_row_height(
      EXPORTING id     = 1
                height = 55
      IMPORTING result = lv_row_rc ).
    go_splitter->set_column_width(
      EXPORTING id     = 1
                width  = 50
      IMPORTING result = lv_col_rc ).
    gv_status = 'Relative mode: first row 55 percent, first column 50 percent'.
  ELSE.
    go_splitter->set_row_mode(
      EXPORTING mode   = cl_gui_splitter_container=>mode_absolute
      IMPORTING result = lv_row_rc ).
    go_splitter->set_column_mode(
      EXPORTING mode   = cl_gui_splitter_container=>mode_absolute
      IMPORTING result = lv_col_rc ).
    go_splitter->set_row_height(
      EXPORTING id     = 1
                height = 220
      IMPORTING result = lv_row_rc ).
    go_splitter->set_column_width(
      EXPORTING id     = 1
                width  = 420
      IMPORTING result = lv_col_rc ).
    gv_status = 'Absolute mode: first row 220 pixels, first column 420 pixels'.
  ENDIF.
  cl_gui_cfw=>flush( ).
  gv_hidden = abap_false.
ENDFORM.

FORM set_minimum_sizes.
* CL_GUI_SPLITTER_CONTAINER exposes no minimum-size API. The sash mode is
* the supported way to stop a row or column from being dragged shut.
  DATA lv_result TYPE i.

  go_splitter->set_row_sash(
    EXPORTING id     = 1
              type   = cl_gui_splitter_container=>type_movable
              value  = cl_gui_splitter_container=>false
    IMPORTING result = lv_result ).
  IF lv_result <> 0.
    gv_status = 'The splitter refused the sash setting'.
    RETURN.
  ENDIF.
  gv_status = 'Row 1 sash fixed; the splitter has no minimum-size API'.
ENDFORM.

FORM apply_sashes.
  DATA lv_rc TYPE i.
  DATA lv_value TYPE i.

  lv_value = COND #( WHEN gv_sashes = abap_true
    THEN cl_gui_splitter_container=>true
    ELSE cl_gui_splitter_container=>false ).
  go_splitter->set_row_sash(
    EXPORTING id     = 1
              type   = cl_gui_splitter_container=>type_movable
              value  = lv_value
    IMPORTING result = lv_rc ).
  go_splitter->set_column_sash(
    EXPORTING id     = 1
              type   = cl_gui_splitter_container=>type_sashvisible
              value  = lv_value
    IMPORTING result = lv_rc ).
  cl_gui_cfw=>flush( ).
  gv_status = |Movable and visible splitter sashes enabled: { gv_sashes }|.
ENDFORM.

FORM read_sizes.
  DATA lv_row_1 TYPE i.
  DATA lv_row_2 TYPE i.
  DATA lv_col_1 TYPE i.
  DATA lv_col_2 TYPE i.

  go_splitter->get_row_height(
    EXPORTING id     = 1
    IMPORTING result = lv_row_1 ).
  go_splitter->get_row_height(
    EXPORTING id     = 2
    IMPORTING result = lv_row_2 ).
  go_splitter->get_column_width( EXPORTING id     = 1
                                 IMPORTING result = lv_col_1 ).
  go_splitter->get_column_width( EXPORTING id     = 2
                                 IMPORTING result = lv_col_2 ).
  cl_gui_cfw=>flush( ).
  gv_status = |Rows { lv_row_1 }/{ lv_row_2 }; columns { lv_col_1 }/{ lv_col_2 }|.
ENDFORM.

FORM free_controls.
  DATA lo_easy_container TYPE REF TO cl_gui_container.

  IF go_easy_right IS BOUND. go_easy_right->free( ). FREE go_easy_right. ENDIF.
  IF go_easy_left IS BOUND. go_easy_left->free( ). FREE go_easy_left. ENDIF.
  IF go_fallback IS BOUND. go_fallback->free( ). FREE go_fallback. ENDIF.
  IF go_easy IS BOUND.
    TRY.
        lo_easy_container ?= go_easy.
        lo_easy_container->free( ).
      CATCH cx_root.
    ENDTRY.
    FREE go_easy.
  ENDIF.
  IF go_nested_right IS BOUND. go_nested_right->free( ). FREE go_nested_right. ENDIF.
  IF go_nested_left IS BOUND. go_nested_left->free( ). FREE go_nested_left. ENDIF.
  IF go_nested IS BOUND. go_nested->free( ). FREE go_nested. ENDIF.
  IF go_html IS BOUND. go_html->free( ). FREE go_html. ENDIF.
  IF go_editor IS BOUND. go_editor->free( ). FREE go_editor. ENDIF.
  IF go_splitter IS BOUND. go_splitter->free( ). FREE go_splitter. ENDIF.
  IF go_host IS BOUND. go_host->free( ). FREE go_host. ENDIF.
ENDFORM.
