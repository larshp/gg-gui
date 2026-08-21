REPORT zgg_gui_classic_list LINE-SIZE 132 LINE-COUNT 25(3).

DATA gt_products TYPE zcl_gg_gui_demo_data=>ty_products.
DATA gv_product_id TYPE c LENGTH 8.
DATA gv_line_number TYPE i.

START-OF-SELECTION.
  gt_products = zcl_gg_gui_demo_data=>products( ).
  IF sy-batch = abap_false.
    SET PF-STATUS 'LIST'.
  ENDIF.
  PERFORM write_main_list.

TOP-OF-PAGE.
  FORMAT COLOR COL_HEADING INTENSIFIED ON.
  WRITE: / 'ZGG_GUI_CLASSIC_LIST - legacy list-processing sample',
         / 'Product', 14 'Name', 47 'Category', 70 'Quantity', 84 'Price', 100 'Status'.
  FORMAT RESET.
  ULINE.

END-OF-PAGE.
  ULINE.
  FORMAT COLOR COL_HEADING.
  WRITE: / 'Page', sy-pagno, 20 'Generated', sy-datum, sy-uzeit,
           60 'Background/spool:', sy-batch.
  FORMAT RESET.

AT LINE-SELECTION.
  IF gv_product_id IS INITIAL.
    MESSAGE 'Select a product hotspot' TYPE 'S'.
    RETURN.
  ENDIF.
  READ TABLE gt_products WITH KEY id = gv_product_id INTO DATA(ls_product).
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.
  SET PF-STATUS 'LIST'.
  FORMAT COLOR COL_HEADING INTENSIFIED ON.
  WRITE: / 'Secondary list - product details'.
  FORMAT RESET.
  ULINE.
  WRITE: / 'Product ID', 20 ls_product-id,
         / 'Name', 20 ls_product-name,
         / 'Category', 20 ls_product-category,
         / 'Quantity', 20 ls_product-quantity,
         / 'Price', 20 ls_product-price CURRENCY ls_product-currency,
         / 'Currency', 20 ls_product-currency,
         / 'Active', 20 ls_product-active,
         / 'Description', 20 ls_product-description.
  SKIP.
  WRITE: / 'Use Back to return to the previous list level.'.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'CHANGE'.
      PERFORM change_current_line.
    WHEN 'TOP'.
      SCROLL LIST TO FIRST PAGE.
    WHEN 'BOTTOM'.
      SCROLL LIST TO LAST PAGE.
    WHEN 'RESET'.
      sy-lsind = 0.
      SCROLL LIST TO FIRST PAGE.
      MESSAGE 'Returned to the main list and first page' TYPE 'S'.
    WHEN 'PRINT'.
      MESSAGE 'Use the standard SAP list print function; background execution writes this list to spool' TYPE 'S'.
    WHEN 'BACK'.
      IF sy-lsind > 0.
        sy-lsind = sy-lsind - 1.
      ELSE.
        LEAVE PROGRAM.
      ENDIF.
    WHEN 'EXIT' OR 'CANCEL'.
      LEAVE PROGRAM.
  ENDCASE.

FORM write_main_list.
  WRITE: / icon_information AS ICON,
    'Legacy UI: use ALV or SALV for new tabular applications unless classic list processing is required.'.
  SKIP.
  LOOP AT gt_products INTO DATA(ls_product).
    gv_product_id = ls_product-id.
    gv_line_number = sy-linno.
    FORMAT COLOR = COND #( WHEN ls_product-active = abap_true THEN COL_NORMAL ELSE COL_NEGATIVE ).
    WRITE: / ls_product-id HOTSPOT COLOR COL_KEY,
             14 ls_product-name,
             47 ls_product-category,
             70 ls_product-quantity,
             84 ls_product-price CURRENCY ls_product-currency,
             100 COND string( WHEN ls_product-active = abap_true THEN 'Active' ELSE 'Inactive' ).
    HIDE: gv_product_id, gv_line_number.
    FORMAT RESET.
  ENDLOOP.
  SKIP 2.
  ULINE AT /1(80).
  WRITE: / icon_display AS ICON, 'Select a product ID for a secondary detail list.'.
  IF sy-batch = abap_true.
    WRITE: / icon_print AS ICON,
      'Background mode: no GUI status or hotspot interaction is required; this primary list is spool-compatible.'.
  ENDIF.
ENDFORM.

FORM change_current_line.
  DATA lv_line TYPE c LENGTH 132.
  DATA lv_changed TYPE c LENGTH 132.
  DATA lv_line_number TYPE i.

  lv_line_number = COND #( WHEN gv_line_number > 0 THEN gv_line_number ELSE sy-lilli ).
  READ LINE lv_line_number LINE VALUE INTO lv_line.
  IF sy-subrc <> 0.
    MESSAGE 'Choose a visible product line before using Change line' TYPE 'S'.
    RETURN.
  ENDIF.
  lv_changed = |* { lv_line }|.
  MODIFY LINE lv_line_number LINE VALUE FROM lv_changed.
  MESSAGE |READ LINE and MODIFY LINE updated list line { lv_line_number }| TYPE 'S'.
ENDFORM.
