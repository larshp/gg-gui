REPORT zgg_gui_alv_classic LINE-SIZE 132 LINE-COUNT 40.

TYPE-POOLS icon.

* Legacy UI: the REUSE_ALV_* function modules are still maintained in many
* systems, but new applications should use CL_SALV_TABLE or CL_GUI_ALV_GRID.
* The whole SLIS type pool and the REUSE_ALV_* surface are missing from
* open-abap, so they are isolated in the static include ZGG_NATIVE_ALV_CLASSIC.

TYPES:
  BEGIN OF ty_merge,
    id       TYPE c LENGTH 8,
    name     TYPE c LENGTH 30,
    category TYPE c LENGTH 20,
    quantity TYPE i,
    price    TYPE p LENGTH 8 DECIMALS 2,
    currency TYPE c LENGTH 3,
  END OF ty_merge,
  ty_merges TYPE STANDARD TABLE OF ty_merge WITH EMPTY KEY.

TYPES:
  BEGIN OF ty_category,
    category TYPE c LENGTH 20,
    products TYPE i,
    quantity TYPE i,
  END OF ty_category,
  ty_categories TYPE STANDARD TABLE OF ty_category WITH EMPTY KEY.

TYPES ty_log_line TYPE c LENGTH 120.
TYPES ty_log TYPE STANDARD TABLE OF ty_log_line WITH EMPTY KEY.

DATA gt_products TYPE ty_merges.
DATA gt_categories TYPE ty_categories.
DATA gt_log TYPE ty_log.
DATA gv_variant TYPE c LENGTH 14.
DATA gv_repid TYPE sy-repid.

PARAMETERS:
  p_grid  RADIOBUTTON GROUP flav DEFAULT 'X',
  p_list  RADIOBUTTON GROUP flav,
  p_hier  RADIOBUTTON GROUP flav,
  p_block RADIOBUTTON GROUP flav,
  p_popup RADIOBUTTON GROUP flav,
  p_event RADIOBUTTON GROUP flav.
PARAMETERS p_merge AS CHECKBOX DEFAULT 'X'.
PARAMETERS p_vari TYPE c LENGTH 14.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_vari.
  PERFORM variant_value_request.

START-OF-SELECTION.
  gv_repid = sy-repid.
  gv_variant = p_vari.
  PERFORM prepare_data.

  IF p_grid = abap_true.
    PERFORM display_grid.
  ELSEIF p_list = abap_true.
    PERFORM display_list.
  ELSEIF p_hier = abap_true.
    PERFORM display_hierseq.
  ELSEIF p_block = abap_true.
    PERFORM display_block_list.
  ELSEIF p_popup = abap_true.
    PERFORM display_popup_to_select.
    PERFORM write_log.
  ELSEIF p_event = abap_true.
    PERFORM display_event_table.
  ENDIF.

FORM prepare_data.
  DATA ls_category TYPE ty_category.
  DATA lt_demo TYPE zcl_gg_gui_demo_data=>ty_products.

  CLEAR: gt_products, gt_categories.
  lt_demo = zcl_gg_gui_demo_data=>products( ).
  LOOP AT lt_demo INTO DATA(ls_product).
    APPEND VALUE #( id       = ls_product-id
                    name     = ls_product-name
                    category = ls_product-category
                    quantity = ls_product-quantity
                    price    = ls_product-price
                    currency = ls_product-currency ) TO gt_products.
  ENDLOOP.

  LOOP AT gt_products INTO DATA(ls_row).
    READ TABLE gt_categories WITH KEY category = ls_row-category
      ASSIGNING FIELD-SYMBOL(<ls_category>).
    IF sy-subrc = 0.
      <ls_category>-products = <ls_category>-products + 1.
      <ls_category>-quantity = <ls_category>-quantity + ls_row-quantity.
      CONTINUE.
    ENDIF.
    CLEAR ls_category.
    ls_category-category = ls_row-category.
    ls_category-products = 1.
    ls_category-quantity = ls_row-quantity.
    APPEND ls_category TO gt_categories.
  ENDLOOP.
ENDFORM.

FORM log USING iv_text TYPE string.
  APPEND iv_text TO gt_log.
ENDFORM.

FORM write_log.
  FORMAT COLOR COL_HEADING INTENSIFIED ON.
  WRITE: / 'ZGG_GUI_ALV_CLASSIC - function-module ALV result log'.
  FORMAT RESET.
  ULINE.
  WRITE: / icon_information AS ICON,
    'Legacy UI: prefer CL_SALV_TABLE or CL_GUI_ALV_GRID for new applications.'.
  SKIP.
  IF gt_log IS INITIAL.
    WRITE: / 'No callback or selection result was recorded'.
  ENDIF.
  LOOP AT gt_log INTO DATA(lv_line).
    WRITE: / lv_line.
  ENDLOOP.
ENDFORM.

INCLUDE zgg_native_alv_classic.
