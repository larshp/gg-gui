REPORT zgg_gui_table_control.

TYPES:
  BEGIN OF ty_row,
    mark     TYPE abap_bool,
    id       TYPE c LENGTH 8,
    name     TYPE c LENGTH 30,
    quantity TYPE i,
    price    TYPE p LENGTH 8 DECIMALS 2,
    currency TYPE c LENGTH 3,
    active   TYPE abap_bool,
  END OF ty_row,
  ty_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

DATA gt_rows TYPE ty_rows.
DATA gs_row TYPE ty_row.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_cursor_field TYPE c LENGTH 40 VALUE 'GS_ROW-NAME'.
DATA gv_cursor_line TYPE i VALUE 1.
DATA gv_top_line TYPE i VALUE 1.
DATA gv_status TYPE c LENGTH 60.

CONTROLS tc_rows TYPE TABLEVIEW USING SCREEN 100.

START-OF-SELECTION.
  PERFORM reset_rows.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  tc_rows-lines = lines( gt_rows ).
  IF gv_top_line > 0 AND gv_top_line <= tc_rows-lines.
    tc_rows-top_line = gv_top_line.
  ENDIF.
ENDMODULE.

MODULE row_attributes OUTPUT.
  LOOP AT SCREEN.
    IF screen-name = 'GS_ROW-ID'.
      screen-input = 0.
      MODIFY SCREEN.
    ELSEIF screen-name = 'GS_ROW-QUANTITY' AND gs_row-active = abap_false.
      screen-input = 0.
      screen-intensified = 1.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.

MODULE restore_cursor OUTPUT.
  IF gv_cursor_line > 0.
    SET CURSOR FIELD gv_cursor_field LINE gv_cursor_line.
  ENDIF.
ENDMODULE.

MODULE validate_row INPUT.
  IF gs_row-name IS INITIAL.
    MESSAGE 'Enter a product name' TYPE 'E'.
  ELSEIF gs_row-quantity < 0.
    MESSAGE 'Quantity cannot be negative' TYPE 'E'.
  ELSEIF gs_row-price < 0.
    MESSAGE 'Price cannot be negative' TYPE 'E'.
  ENDIF.
ENDMODULE.

MODULE update_row INPUT.
  MODIFY gt_rows FROM gs_row INDEX tc_rows-current_line.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA lv_ok_code TYPE sy-ucomm.
  DATA lv_visible_line TYPE i.
  DATA lv_index TYPE i.
  DATA ls_source TYPE ty_row.

  lv_ok_code = gv_ok_code.
  CLEAR gv_ok_code.
  GET CURSOR FIELD gv_cursor_field LINE lv_visible_line.
  IF lv_visible_line > 0.
    gv_cursor_line = lv_visible_line.
  ENDIF.
  gv_top_line = tc_rows-top_line.

  CASE lv_ok_code.
    WHEN 'APPEND'.
      APPEND VALUE #(
        id = |P{ lines( gt_rows ) + 500 }|
        name = 'New product'
        currency = 'EUR'
        active = abap_true ) TO gt_rows.
      gv_status = 'A row was appended'.
    WHEN 'INSERT'.
      lv_index = tc_rows-top_line + gv_cursor_line - 1.
      IF lv_index < 1 OR lv_index > lines( gt_rows ).
        lv_index = 1.
      ENDIF.
      INSERT VALUE #(
        id = |P{ lines( gt_rows ) + 500 }|
        name = 'Inserted product'
        currency = 'EUR'
        active = abap_true ) INTO gt_rows INDEX lv_index.
      gv_status = |A row was inserted at position { lv_index }|.
    WHEN 'COPY'.
      READ TABLE gt_rows INTO ls_source WITH KEY mark = abap_true.
      IF sy-subrc = 0.
        CLEAR ls_source-mark.
        ls_source-id = |P{ lines( gt_rows ) + 500 }|.
        ls_source-name = |Copy of { ls_source-name }|.
        APPEND ls_source TO gt_rows.
        gv_status = 'The first marked row was copied'.
      ELSE.
        gv_status = 'Mark a row before copying'.
      ENDIF.
    WHEN 'DELETE'.
      DELETE gt_rows WHERE mark = abap_true.
      gv_status = |{ sy-dbcnt } marked row(s) deleted|.
      IF gt_rows IS INITIAL.
        APPEND VALUE #( id = 'P500' name = 'New product'
          currency = 'EUR' active = abap_true ) TO gt_rows.
      ENDIF.
    WHEN 'RESET'.
      PERFORM reset_rows.
      gv_status = 'Initial rows restored'.
      gv_top_line = 1.
      gv_cursor_line = 1.
  ENDCASE.
ENDMODULE.

FORM reset_rows.
  gt_rows = VALUE #(
    ( id = 'P100' name = 'Mechanical Keyboard' quantity = 12
      price = '129.90' currency = 'EUR' active = abap_true )
    ( id = 'P110' name = 'Ergonomic Mouse' quantity = 7
      price = '74.50' currency = 'EUR' active = abap_true )
    ( id = 'P200' name = '27 Inch Display' quantity = 4
      price = '389.00' currency = 'EUR' active = abap_true )
    ( id = 'P300' name = 'USB-C Dock' quantity = 0
      price = '219.00' currency = 'EUR' active = abap_false )
    ( id = 'P400' name = 'Conference Speaker' quantity = 9
      price = '159.00' currency = 'EUR' active = abap_true ) ).
ENDFORM.
