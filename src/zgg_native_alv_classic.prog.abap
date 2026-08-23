* Static include owned by ZGG_GUI_ALV_CLASSIC.
* The SLIS type pool and the REUSE_ALV_* function modules are part of the
* native SAP list-ALV surface and are absent from the open-abap dependency
* surface, so all code that depends on them is isolated here. Lint issue
* reporting is disabled for this include; activation, the callbacks, and the
* displayed lists remain native SAP checks.

TYPE-POOLS slis.

FORM build_product_fieldcat CHANGING ct_fieldcat TYPE slis_t_fieldcat_alv.
  DATA ls_fieldcat TYPE slis_fieldcat_alv.

  CLEAR ct_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-tabname   = 'GT_PRODUCTS'.
  ls_fieldcat-fieldname = 'ID'.
  ls_fieldcat-seltext_l = 'Product'.
  ls_fieldcat-key       = abap_true.
  ls_fieldcat-outputlen = 10.
  ls_fieldcat-hotspot   = abap_true.
  APPEND ls_fieldcat TO ct_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-tabname   = 'GT_PRODUCTS'.
  ls_fieldcat-fieldname = 'NAME'.
  ls_fieldcat-seltext_l = 'Description'.
  ls_fieldcat-outputlen = 30.
  APPEND ls_fieldcat TO ct_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-tabname   = 'GT_PRODUCTS'.
  ls_fieldcat-fieldname = 'CATEGORY'.
  ls_fieldcat-seltext_l = 'Category'.
  ls_fieldcat-outputlen = 20.
  APPEND ls_fieldcat TO ct_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-tabname   = 'GT_PRODUCTS'.
  ls_fieldcat-fieldname = 'QUANTITY'.
  ls_fieldcat-seltext_l = 'Quantity'.
  ls_fieldcat-outputlen = 10.
  ls_fieldcat-do_sum    = abap_true.
  APPEND ls_fieldcat TO ct_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-tabname    = 'GT_PRODUCTS'.
  ls_fieldcat-fieldname  = 'PRICE'.
  ls_fieldcat-seltext_l  = 'Price'.
  ls_fieldcat-datatype   = 'CURR'.
  ls_fieldcat-cfieldname = 'CURRENCY'.
  ls_fieldcat-ctabname   = 'GT_PRODUCTS'.
  ls_fieldcat-do_sum     = abap_true.
  ls_fieldcat-outputlen  = 14.
  APPEND ls_fieldcat TO ct_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-tabname   = 'GT_PRODUCTS'.
  ls_fieldcat-fieldname = 'CURRENCY'.
  ls_fieldcat-seltext_l = 'Currency'.
  ls_fieldcat-outputlen = 8.
  APPEND ls_fieldcat TO ct_fieldcat.
ENDFORM.

FORM build_category_fieldcat CHANGING ct_fieldcat TYPE slis_t_fieldcat_alv.
  DATA ls_fieldcat TYPE slis_fieldcat_alv.

  CLEAR ct_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-tabname   = 'GT_CATEGORIES'.
  ls_fieldcat-fieldname = 'CATEGORY'.
  ls_fieldcat-seltext_l = 'Category'.
  ls_fieldcat-key       = abap_true.
  ls_fieldcat-outputlen = 20.
  APPEND ls_fieldcat TO ct_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-tabname   = 'GT_CATEGORIES'.
  ls_fieldcat-fieldname = 'PRODUCTS'.
  ls_fieldcat-seltext_l = 'Products'.
  ls_fieldcat-outputlen = 10.
  APPEND ls_fieldcat TO ct_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-tabname   = 'GT_CATEGORIES'.
  ls_fieldcat-fieldname = 'QUANTITY'.
  ls_fieldcat-seltext_l = 'Total quantity'.
  ls_fieldcat-outputlen = 14.
  ls_fieldcat-do_sum    = abap_true.
  APPEND ls_fieldcat TO ct_fieldcat.
ENDFORM.

* The merge reads the field description of a globally declared internal table
* out of the program itself instead of a DDIC structure.
FORM merge_product_fieldcat CHANGING ct_fieldcat TYPE slis_t_fieldcat_alv.
  DATA lt_merged TYPE slis_t_fieldcat_alv.
  DATA lv_message TYPE string.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name         = gv_repid
      i_internal_tabname     = 'GT_PRODUCTS'
      i_inclname             = gv_repid
    CHANGING
      ct_fieldcat            = lt_merged
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
    PERFORM log USING 'REUSE_ALV_FIELDCATALOG_MERGE failed; the manual catalog is used'.
    RETURN.
  ENDIF.

  lv_message = |Merged field catalog has { lines( lt_merged ) } columns from the program symbol table|.
  PERFORM log USING lv_message.

* Column texts are taken over from the manual catalog because the sample
* structure has no DDIC reference fields.
  LOOP AT lt_merged ASSIGNING FIELD-SYMBOL(<ls_merged>).
    READ TABLE ct_fieldcat INTO DATA(ls_manual)
      WITH KEY fieldname = <ls_merged>-fieldname.
    IF sy-subrc = 0.
      <ls_merged>-seltext_l  = ls_manual-seltext_l.
      <ls_merged>-key        = ls_manual-key.
      <ls_merged>-do_sum     = ls_manual-do_sum.
      <ls_merged>-hotspot    = ls_manual-hotspot.
      <ls_merged>-cfieldname = ls_manual-cfieldname.
      <ls_merged>-ctabname   = ls_manual-ctabname.
    ENDIF.
  ENDLOOP.
  ct_fieldcat = lt_merged.
ENDFORM.

FORM build_layout CHANGING cs_layout TYPE slis_layout_alv.
  CLEAR cs_layout.
  cs_layout-zebra             = abap_true.
  cs_layout-colwidth_optimize = abap_true.
  cs_layout-detail_popup      = abap_true.
  cs_layout-detail_titlebar   = 'Product detail'.
ENDFORM.

FORM build_sort CHANGING ct_sort TYPE slis_t_sortinfo_alv.
  DATA ls_sort TYPE slis_sortinfo_alv.

  CLEAR ct_sort.
  ls_sort-spos      = 1.
  ls_sort-tabname   = 'GT_PRODUCTS'.
  ls_sort-fieldname = 'CATEGORY'.
  ls_sort-up        = abap_true.
  ls_sort-subtot    = abap_true.
  APPEND ls_sort TO ct_sort.
ENDFORM.

FORM display_grid.
  DATA lt_fieldcat TYPE slis_t_fieldcat_alv.
  DATA lt_sort TYPE slis_t_sortinfo_alv.
  DATA ls_layout TYPE slis_layout_alv.
  DATA ls_variant TYPE disvariant.

  PERFORM build_product_fieldcat CHANGING lt_fieldcat.
  IF p_merge = abap_true.
    PERFORM merge_product_fieldcat CHANGING lt_fieldcat.
  ENDIF.
  PERFORM build_layout CHANGING ls_layout.
  PERFORM build_sort CHANGING lt_sort.

  ls_variant-report  = gv_repid.
  ls_variant-variant = gv_variant.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = gv_repid
      i_callback_pf_status_set = 'PF_STATUS_SET'
      i_callback_user_command  = 'USER_COMMAND'
      i_callback_top_of_page   = 'TOP_OF_PAGE'
      i_grid_title             = 'Classic ALV grid display'
      is_layout                = ls_layout
      it_fieldcat              = lt_fieldcat
      it_sort                  = lt_sort
      i_save                   = 'A'
      is_variant               = ls_variant
    TABLES
      t_outtab                 = gt_products
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.
  IF sy-subrc <> 0.
    MESSAGE 'REUSE_ALV_GRID_DISPLAY reported a program error' TYPE 'S'
      DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

FORM display_list.
  DATA lt_fieldcat TYPE slis_t_fieldcat_alv.
  DATA lt_events TYPE slis_t_event.
  DATA ls_layout TYPE slis_layout_alv.

  PERFORM build_product_fieldcat CHANGING lt_fieldcat.
  PERFORM build_layout CHANGING ls_layout.
  PERFORM collect_events USING 0 CHANGING lt_events.

  CALL FUNCTION 'REUSE_ALV_LIST_DISPLAY'
    EXPORTING
      i_callback_program      = gv_repid
      i_callback_user_command = 'USER_COMMAND'
      is_layout               = ls_layout
      it_fieldcat             = lt_fieldcat
      it_events               = lt_events
      i_save                  = 'A'
    TABLES
      t_outtab                = gt_products
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.
  IF sy-subrc <> 0.
    MESSAGE 'REUSE_ALV_LIST_DISPLAY reported a program error' TYPE 'S'
      DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

FORM display_hierseq.
  DATA lt_fieldcat TYPE slis_t_fieldcat_alv.
  DATA lt_item_fieldcat TYPE slis_t_fieldcat_alv.
  DATA ls_layout TYPE slis_layout_alv.
  DATA ls_keyinfo TYPE slis_keyinfo_alv.

  PERFORM build_category_fieldcat CHANGING lt_fieldcat.
  PERFORM build_product_fieldcat CHANGING lt_item_fieldcat.
  APPEND LINES OF lt_item_fieldcat TO lt_fieldcat.
  PERFORM build_layout CHANGING ls_layout.
  ls_layout-expand_all = abap_true.

  ls_keyinfo-header01 = 'CATEGORY'.
  ls_keyinfo-item01   = 'CATEGORY'.

  CALL FUNCTION 'REUSE_ALV_HIERSEQ_LIST_DISPLAY'
    EXPORTING
      i_callback_program      = gv_repid
      i_callback_user_command = 'USER_COMMAND'
      is_layout               = ls_layout
      it_fieldcat             = lt_fieldcat
      i_tabname_header        = 'GT_CATEGORIES'
      i_tabname_item          = 'GT_PRODUCTS'
      is_keyinfo              = ls_keyinfo
      i_save                  = 'A'
    TABLES
      t_outtab_header         = gt_categories
      t_outtab_item           = gt_products
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.
  IF sy-subrc <> 0.
    MESSAGE 'REUSE_ALV_HIERSEQ_LIST_DISPLAY reported a program error' TYPE 'S'
      DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

FORM display_block_list.
  DATA lt_category_fieldcat TYPE slis_t_fieldcat_alv.
  DATA lt_product_fieldcat TYPE slis_t_fieldcat_alv.
  DATA lt_events TYPE slis_t_event.
  DATA ls_layout TYPE slis_layout_alv.

  PERFORM build_category_fieldcat CHANGING lt_category_fieldcat.
  PERFORM build_product_fieldcat CHANGING lt_product_fieldcat.
  PERFORM build_layout CHANGING ls_layout.
  PERFORM collect_events USING 2 CHANGING lt_events.

  CALL FUNCTION 'REUSE_ALV_BLOCK_LIST_INIT'
    EXPORTING
      i_callback_program = gv_repid.

  CALL FUNCTION 'REUSE_ALV_BLOCK_LIST_APPEND'
    EXPORTING
      is_layout                  = ls_layout
      it_fieldcat                = lt_category_fieldcat
      i_tabname                  = 'GT_CATEGORIES'
      it_events                  = lt_events
    TABLES
      t_outtab                   = gt_categories
    EXCEPTIONS
      program_error              = 1
      maximum_of_appends_reached = 2
      OTHERS                     = 3.
  IF sy-subrc <> 0.
    MESSAGE 'The category block could not be appended' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_BLOCK_LIST_APPEND'
    EXPORTING
      is_layout                  = ls_layout
      it_fieldcat                = lt_product_fieldcat
      i_tabname                  = 'GT_PRODUCTS'
      it_events                  = lt_events
    TABLES
      t_outtab                   = gt_products
    EXCEPTIONS
      program_error              = 1
      maximum_of_appends_reached = 2
      OTHERS                     = 3.
  IF sy-subrc <> 0.
    MESSAGE 'The product block could not be appended' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_BLOCK_LIST_DISPLAY'
    EXCEPTIONS
      program_error = 1
      OTHERS        = 2.
  IF sy-subrc <> 0.
    MESSAGE 'REUSE_ALV_BLOCK_LIST_DISPLAY reported a program error' TYPE 'S'
      DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

FORM display_popup_to_select.
  DATA lt_fieldcat TYPE slis_t_fieldcat_alv.
  DATA ls_selfield TYPE slis_selfield.
  DATA lv_exit TYPE c LENGTH 1.
  DATA lv_message TYPE string.

  PERFORM build_product_fieldcat CHANGING lt_fieldcat.

  CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT'
    EXPORTING
      i_title               = 'Choose a product'
      i_selection           = abap_true
      i_zebra               = abap_true
      i_tabname             = 'GT_PRODUCTS'
      it_fieldcat           = lt_fieldcat
      i_callback_program    = gv_repid
      i_screen_start_column = 10
      i_screen_start_line   = 4
      i_screen_end_column   = 100
      i_screen_end_line     = 16
    IMPORTING
      es_selfield           = ls_selfield
      e_exit                = lv_exit
    TABLES
      t_outtab              = gt_products
    EXCEPTIONS
      program_error         = 1
      OTHERS                = 2.
  IF sy-subrc <> 0.
    PERFORM log USING 'REUSE_ALV_POPUP_TO_SELECT reported a program error'.
    RETURN.
  ENDIF.
  IF lv_exit = abap_true.
    PERFORM log USING 'The selection popup was left without choosing a row'.
    RETURN.
  ENDIF.

  READ TABLE gt_products INDEX ls_selfield-tabindex INTO DATA(ls_product).
  IF sy-subrc = 0.
    lv_message = |Popup selection: row { ls_selfield-tabindex }, product { ls_product-id } { ls_product-name }|.
    PERFORM log USING lv_message.
  ENDIF.
ENDFORM.

FORM collect_events USING iv_list_type TYPE i
                    CHANGING ct_events TYPE slis_t_event.
  DATA ls_event TYPE slis_alv_event.

  CLEAR ct_events.
  CALL FUNCTION 'REUSE_ALV_EVENTS_GET'
    EXPORTING
      i_list_type     = iv_list_type
    IMPORTING
      et_events       = ct_events
    EXCEPTIONS
      list_type_wrong = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
    PERFORM log USING 'REUSE_ALV_EVENTS_GET rejected the requested list type'.
    RETURN.
  ENDIF.

* Only the events that the sample implements receive a form routine name.
  READ TABLE ct_events WITH KEY name = 'TOP_OF_PAGE' INTO ls_event.
  IF sy-subrc = 0.
    ls_event-form = 'TOP_OF_PAGE'.
    MODIFY ct_events FROM ls_event INDEX sy-tabix.
  ENDIF.
  READ TABLE ct_events WITH KEY name = 'END_OF_LIST' INTO ls_event.
  IF sy-subrc = 0.
    ls_event-form = 'END_OF_LIST'.
    MODIFY ct_events FROM ls_event INDEX sy-tabix.
  ENDIF.
ENDFORM.

FORM display_event_table.
  DATA lt_simple TYPE slis_t_event.
  DATA lt_hierseq TYPE slis_t_event.
  DATA lv_message TYPE string.

  PERFORM collect_events USING 0 CHANGING lt_simple.
  PERFORM collect_events USING 1 CHANGING lt_hierseq.

  lv_message = |Simple list offers { lines( lt_simple ) } events, hierarchical-sequential { lines( lt_hierseq ) }|.
  PERFORM log USING lv_message.
  LOOP AT lt_simple INTO DATA(ls_event).
    IF ls_event-form IS INITIAL.
      lv_message = |{ ls_event-name } (no form routine implemented)|.
    ELSE.
      lv_message = |{ ls_event-name } handled by FORM { ls_event-form }|.
    ENDIF.
    PERFORM log USING lv_message.
  ENDLOOP.
  PERFORM write_log.
ENDFORM.

FORM variant_value_request.
  DATA ls_variant TYPE disvariant.
  DATA lv_exit TYPE c LENGTH 1.

  ls_variant-report = sy-repid.
  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING
      is_variant    = ls_variant
      i_save        = 'A'
    IMPORTING
      e_exit        = lv_exit
      es_variant    = ls_variant
    EXCEPTIONS
      not_found     = 1
      program_error = 2
      OTHERS        = 3.
  IF sy-subrc = 0 AND lv_exit <> abap_true.
    p_vari = ls_variant-variant.
  ENDIF.
ENDFORM.

* Callback executed by the ALV before the list is displayed. The status is
* copied from the standard list-ALV function group instead of a local status.
FORM pf_status_set USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS 'STANDARD' OF PROGRAM 'SAPLKKBL' EXCLUDING rt_extab.
ENDFORM.

FORM user_command USING r_ucomm TYPE sy-ucomm
                        rs_selfield TYPE slis_selfield.
  DATA lv_message TYPE string.

  CASE r_ucomm.
    WHEN '&IC1'.
      READ TABLE gt_products INDEX rs_selfield-tabindex INTO DATA(ls_product).
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      lv_message = |{ ls_product-id } { ls_product-name }, { ls_product-quantity } pieces|.
      MESSAGE lv_message TYPE 'I'.
      PERFORM log USING lv_message.
      rs_selfield-refresh = abap_true.
    WHEN '&NTE'.
      rs_selfield-exit = abap_true.
  ENDCASE.
ENDFORM.

FORM top_of_page.
  DATA lt_commentary TYPE slis_t_listheader.
  DATA ls_line TYPE slis_listheader.

  ls_line-typ  = 'H'.
  ls_line-info = 'ZGG_GUI_ALV_CLASSIC - function-module ALV'.
  APPEND ls_line TO lt_commentary.

  CLEAR ls_line.
  ls_line-typ  = 'S'.
  ls_line-key  = 'Rows'.
  ls_line-info = |{ lines( gt_products ) }|.
  APPEND ls_line TO lt_commentary.

  CLEAR ls_line.
  ls_line-typ  = 'A'.
  ls_line-info = 'Legacy UI: new applications should use SALV or the ALV Grid Control'.
  APPEND ls_line TO lt_commentary.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_commentary.
ENDFORM.

FORM end_of_list.
  ULINE.
  WRITE: / 'End of list written by the END_OF_LIST event of the list ALV'.
ENDFORM.
