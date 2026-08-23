* Static include owned by ZGG_GUI_SEL_VARIANTS.
* RSPARAMS, VARID, VARIT, and the RS_VARIANT_* function modules belong to the
* native selection-variant surface and are absent from the open-abap
* dependency surface, so every statement that needs them is isolated here.
* Lint issue reporting is disabled for this include; activation, variant
* persistence, and the started reports remain native SAP checks.

TYPES ty_params TYPE STANDARD TABLE OF rsparams WITH EMPTY KEY.

FORM collect_current_selection CHANGING ct_params TYPE ty_params.
  CLEAR ct_params.
  CALL FUNCTION 'RS_REFRESH_FROM_SELECTOPTIONS'
    EXPORTING
      curr_report     = sy-repid
    TABLES
      selection_table = ct_params
    EXCEPTIONS
      not_found       = 1
      no_report       = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    PERFORM log USING 'The current selection values could not be read'.
  ENDIF.
ENDFORM.

FORM variant_value_request.
  DATA lv_variant TYPE rsvar-variant.
  DATA lv_message TYPE string.

  CALL FUNCTION 'RS_VARIANT_CATALOG'
    EXPORTING
      report               = sy-repid
      new_title            = 'Variants of the sample report'
    IMPORTING
      sel_variant          = lv_variant
    EXCEPTIONS
      no_report            = 1
      report_not_existent  = 2
      report_not_supplied  = 3
      no_variants          = 4
      variant_not_existent = 5
      OTHERS               = 6.
  IF sy-subrc <> 0.
    PERFORM log USING 'No variant catalog is available for this report yet'.
    RETURN.
  ENDIF.
  IF lv_variant IS INITIAL.
    RETURN.
  ENDIF.
  p_vari = lv_variant.
  lv_message = |Variant { p_vari } was chosen in the catalog popup|.
  PERFORM log USING lv_message.
ENDFORM.

FORM show_variant_contents.
  DATA lt_params TYPE ty_params.
  DATA lv_message TYPE string.

  CALL FUNCTION 'RS_VARIANT_CONTENTS'
    EXPORTING
      report               = sy-repid
      variant              = p_vari
    TABLES
      valutab              = lt_params
    EXCEPTIONS
      variant_non_existent = 1
      variant_obsolete     = 2
      OTHERS               = 3.
  IF sy-subrc <> 0.
    lv_message = |Variant { p_vari } does not exist or is obsolete|.
    PERFORM log USING lv_message.
    RETURN.
  ENDIF.

  lv_message = |Variant { p_vari } stores { lines( lt_params ) } selection entries|.
  PERFORM log USING lv_message.
  LOOP AT lt_params INTO DATA(ls_param).
    lv_message = |{ ls_param-selname } kind { ls_param-kind } | &&
                 |{ ls_param-sign }{ ls_param-option } { ls_param-low } { ls_param-high }|.
    PERFORM log USING lv_message.
  ENDLOOP.
ENDFORM.

FORM save_sample_variant.
  DATA lt_params TYPE ty_params.
  DATA lt_text TYPE STANDARD TABLE OF varit WITH EMPTY KEY.
  DATA ls_description TYPE varid.
  DATA lv_allowed TYPE abap_bool.
  DATA lv_confirmed TYPE abap_bool.
  DATA lv_question TYPE string.
  DATA lv_message TYPE string.

  PERFORM check_sample_variant CHANGING lv_allowed.
  IF lv_allowed = abap_false.
    RETURN.
  ENDIF.

  lv_question = |Save the current selection values as variant { p_vari }?|.
  PERFORM confirm USING lv_question CHANGING lv_confirmed.
  IF lv_confirmed = abap_false.
    PERFORM log USING 'Variant save canceled; nothing was written'.
    RETURN.
  ENDIF.

  PERFORM collect_current_selection CHANGING lt_params.
  IF lt_params IS INITIAL.
    PERFORM log USING 'No selection values were returned; the variant was not saved'.
    RETURN.
  ENDIF.

  ls_description-report     = sy-repid.
  ls_description-variant    = p_vari.
  ls_description-mandt      = sy-mandt.
  ls_description-ename      = sy-uname.
  ls_description-edat       = sy-datum.
  ls_description-etime      = sy-uzeit.
  ls_description-environmnt = 'A'.

  APPEND VALUE #( mandt   = sy-mandt
                  langu   = sy-langu
                  report  = sy-repid
                  variant = p_vari
                  vtext   = 'GG GUI sample variant' ) TO lt_text.

  CALL FUNCTION 'RS_CREATE_VARIANT'
    EXPORTING
      curr_report               = sy-repid
      curr_variant              = p_vari
      vari_desc                 = ls_description
    TABLES
      vari_contents             = lt_params
      vari_text                 = lt_text
    EXCEPTIONS
      illegal_report_or_variant = 1
      illegal_variantname       = 2
      not_authorized            = 3
      not_executed              = 4
      report_not_existent       = 5
      report_not_supplied       = 6
      variant_exists            = 7
      variant_locked            = 8
      OTHERS                    = 9.
  CASE sy-subrc.
    WHEN 0.
      lv_message = |Variant { p_vari } was created with { lines( lt_params ) } entries|.
      PERFORM log USING lv_message.
      RETURN.
    WHEN 7.
*     The variant already exists, so the stored values are replaced instead.
    WHEN OTHERS.
      lv_message = |Variant { p_vari } could not be created (SY-SUBRC { sy-subrc })|.
      PERFORM log USING lv_message.
      RETURN.
  ENDCASE.

  CALL FUNCTION 'RS_CHANGE_CREATED_VARIANT'
    EXPORTING
      curr_report               = sy-repid
      curr_variant              = p_vari
      vari_desc                 = ls_description
    TABLES
      vari_contents             = lt_params
      vari_text                 = lt_text
    EXCEPTIONS
      illegal_report_or_variant = 1
      illegal_variantname       = 2
      not_authorized            = 3
      not_executed              = 4
      report_not_existent       = 5
      report_not_supplied       = 6
      variant_doesnt_exist      = 7
      variant_locked            = 8
      selections_no_match       = 9
      OTHERS                    = 10.
  IF sy-subrc = 0.
    lv_message = |Variant { p_vari } was updated with the current values|.
  ELSE.
    lv_message = |Variant { p_vari } could not be updated (SY-SUBRC { sy-subrc })|.
  ENDIF.
  PERFORM log USING lv_message.
ENDFORM.

FORM delete_sample_variant.
  DATA lv_allowed TYPE abap_bool.
  DATA lv_confirmed TYPE abap_bool.
  DATA lv_question TYPE string.
  DATA lv_message TYPE string.

  PERFORM check_sample_variant CHANGING lv_allowed.
  IF lv_allowed = abap_false.
    RETURN.
  ENDIF.

  lv_question = |Delete the sample variant { p_vari }?|.
  PERFORM confirm USING lv_question CHANGING lv_confirmed.
  IF lv_confirmed = abap_false.
    PERFORM log USING 'Variant deletion canceled; the variant was kept'.
    RETURN.
  ENDIF.

  CALL FUNCTION 'RS_VARIANT_DELETE'
    EXPORTING
      report               = sy-repid
      variant              = p_vari
      flag_confirmscreen   = abap_true
    EXCEPTIONS
      not_authorized       = 1
      no_report            = 2
      report_not_existent  = 3
      report_not_supplied  = 4
      variant_locked       = 5
      variant_not_existent = 6
      no_corr_insert       = 7
      variant_protected    = 8
      OTHERS               = 9.
  IF sy-subrc = 0.
    lv_message = |Variant { p_vari } was deleted|.
  ELSE.
    lv_message = |Variant { p_vari } was not deleted (SY-SUBRC { sy-subrc })|.
  ENDIF.
  PERFORM log USING lv_message.
ENDFORM.

* Selection values can also be passed to another report without a variant.
FORM build_range_selection CHANGING ct_params TYPE ty_params.
  CLEAR ct_params.
  APPEND VALUE #( selname = 'S_NUMBER' kind = 'S' sign = 'I'
                  option = 'BT' low = '10' high = '40' ) TO ct_params.
  APPEND VALUE #( selname = 'S_REQ' kind = 'S' sign = 'I'
                  option = 'EQ' low = '5' ) TO ct_params.
ENDFORM.

FORM submit_with_selection_table.
  DATA lt_params TYPE ty_params.
  DATA lv_message TYPE string.

  PERFORM build_range_selection CHANGING lt_params.
  lv_message = |SUBMIT ZGG_GUI_SEL_RANGES with { lines( lt_params ) } selection-table rows|.
  PERFORM log USING lv_message.
  SUBMIT zgg_gui_sel_ranges WITH SELECTION-TABLE lt_params AND RETURN.
  PERFORM log USING 'Returned from the report started with WITH SELECTION-TABLE'.
ENDFORM.

FORM submit_via_selection_screen.
  DATA lt_params TYPE ty_params.

  PERFORM build_range_selection CHANGING lt_params.
  PERFORM log USING 'VIA SELECTION-SCREEN shows the prepared values before execution'.
  SUBMIT zgg_gui_sel_ranges
    WITH SELECTION-TABLE lt_params
    VIA SELECTION-SCREEN AND RETURN.
  PERFORM log USING 'Returned from the report started with VIA SELECTION-SCREEN'.
ENDFORM.

FORM submit_using_variant.
  DATA lt_params TYPE ty_params.
  DATA lv_message TYPE string.

  CALL FUNCTION 'RS_VARIANT_CONTENTS'
    EXPORTING
      report               = sy-repid
      variant              = p_vari
    TABLES
      valutab              = lt_params
    EXCEPTIONS
      variant_non_existent = 1
      variant_obsolete     = 2
      OTHERS               = 3.
  IF sy-subrc <> 0.
    lv_message = |Variant { p_vari } must be saved before it can be started|.
    PERFORM log USING lv_message.
    RETURN.
  ENDIF.

  lv_message = |SUBMIT of this report USING SELECTION-SET { p_vari }|.
  PERFORM log USING lv_message.
  SUBMIT zgg_gui_sel_variants USING SELECTION-SET p_vari AND RETURN.
  PERFORM log USING 'Returned from the report started with USING SELECTION-SET'.
ENDFORM.
