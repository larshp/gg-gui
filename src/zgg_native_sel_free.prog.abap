* Static include owned by ZGG_GUI_SEL_FREE.
* The RSDS* dynamic-selection types and the FREE_SELECTIONS_* function modules
* belong to the native selection surface and are absent from the open-abap
* dependency surface, so every statement that needs them is isolated here.
* Lint issue reporting is disabled for this include; activation and the
* interactive dialog remain native SAP checks.

TYPES ty_tables TYPE STANDARD TABLE OF rsdstabs WITH EMPTY KEY.
TYPES ty_fields TYPE STANDARD TABLE OF rsdsfields WITH EMPTY KEY.

CONSTANTS gc_table TYPE c LENGTH 30 VALUE 'T100'.

DATA gv_selection_id TYPE rsdynsel-selid.
DATA gt_free_fields TYPE ty_fields.
DATA gs_expressions TYPE rsds_texpr.
DATA gt_field_ranges TYPE rsds_trange.

FORM init_free_selections CHANGING cv_ready TYPE abap_bool.
  DATA lt_tables TYPE ty_tables.
  DATA lv_message TYPE string.

  CLEAR cv_ready.
  IF gv_selection_id IS NOT INITIAL.
    cv_ready = abap_true.
    RETURN.
  ENDIF.

* Offering complete tables lets the user add any field of the table; the
* preselected fields are the ones shown when the dialog opens.
  APPEND VALUE #( prim_tab = gc_table ) TO lt_tables.
  gt_free_fields = VALUE #(
    ( tablename = gc_table fieldname = 'SPRSL' )
    ( tablename = gc_table fieldname = 'ARBGB' )
    ( tablename = gc_table fieldname = 'MSGNR' ) ).

  CALL FUNCTION 'FREE_SELECTIONS_INIT'
    EXPORTING
      kind                     = 'T'
      field_ranges_int         = gt_field_ranges
    IMPORTING
      selection_id             = gv_selection_id
    TABLES
      tables_tab               = lt_tables
      fields_tab               = gt_free_fields
    EXCEPTIONS
      fields_incomplete        = 1
      fields_no_join           = 2
      field_not_found          = 3
      no_tables                = 4
      table_not_found          = 5
      expression_not_supported = 6
      incorrect_expression     = 7
      illegal_kind             = 8
      area_not_found           = 9
      inherited_error          = 10
      program_error            = 11
      no_limitation            = 12
      OTHERS                   = 13.
  IF sy-subrc <> 0.
    lv_message = |FREE_SELECTIONS_INIT failed for { gc_table } (SY-SUBRC { sy-subrc })|.
    PERFORM log USING lv_message.
    CLEAR gv_selection_id.
    RETURN.
  ENDIF.
  cv_ready = abap_true.
ENDFORM.

FORM open_free_selections USING iv_as_window TYPE abap_bool.
  DATA lt_where TYPE rsds_twhere.
  DATA lv_ready TYPE abap_bool.
  DATA lv_message TYPE string.

  PERFORM init_free_selections CHANGING lv_ready.
  IF lv_ready = abap_false.
    RETURN.
  ENDIF.

  CALL FUNCTION 'FREE_SELECTIONS_DIALOG'
    EXPORTING
      selection_id            = gv_selection_id
      title                   = 'Dynamic selections'
      as_window               = iv_as_window
      start_row               = 4
      start_col               = 10
      tree_visible            = abap_true
    IMPORTING
      where_clauses           = lt_where
      expressions             = gs_expressions
      field_ranges            = gt_field_ranges
      number_of_active_fields = gv_active
    TABLES
      fields_tab              = gt_free_fields
    EXCEPTIONS
      internal_error          = 1
      no_action               = 2
      selid_not_found         = 3
      illegal_status          = 4
      OTHERS                  = 5.
  CASE sy-subrc.
    WHEN 0.
*     Continue below with the returned selection.
    WHEN 2.
      PERFORM log USING 'The dynamic selection dialog was canceled; the previous selection is kept'.
      RETURN.
    WHEN OTHERS.
      lv_message = |FREE_SELECTIONS_DIALOG returned SY-SUBRC { sy-subrc }|.
      PERFORM log USING lv_message.
      RETURN.
  ENDCASE.

  IF iv_as_window = abap_true.
    PERFORM log USING 'Dialog displayed as a modal window with the field tree visible'.
  ELSE.
    PERFORM log USING 'Dialog displayed as a full screen'.
  ENDIF.
  lv_message = |{ gv_active } dynamic selection fields are active|.
  PERFORM log USING lv_message.

  PERFORM log_ranges.
  PERFORM log_where_clauses USING lt_where.
  PERFORM log_generated_where.
ENDFORM.

FORM log_ranges.
  DATA lv_message TYPE string.

  LOOP AT gt_field_ranges INTO DATA(ls_range).
    LOOP AT ls_range-frange_t INTO DATA(ls_field).
      LOOP AT ls_field-selopt_t INTO DATA(ls_selopt).
        lv_message = |Range { ls_range-tablename }-{ ls_field-fieldname }: | &&
                     |{ ls_selopt-sign }{ ls_selopt-option } { ls_selopt-low } { ls_selopt-high }|.
        PERFORM log USING lv_message.
      ENDLOOP.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

FORM log_where_clauses USING it_where TYPE rsds_twhere.
  DATA lv_message TYPE string.

  LOOP AT it_where INTO DATA(ls_where).
    LOOP AT ls_where-where_tab INTO DATA(ls_line).
      lv_message = |WHERE { ls_where-tablename }: { ls_line-line }|.
      PERFORM log USING lv_message.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

* The range table can be converted back into a WHERE clause at any time, which
* is what an application does before it reads data with the dynamic selection.
FORM log_generated_where.
  DATA lt_where TYPE rsds_twhere.
  DATA lv_message TYPE string.

  IF gt_field_ranges IS INITIAL.
    RETURN.
  ENDIF.

  CALL FUNCTION 'FREE_SELECTIONS_RANGE_2_WHERE'
    EXPORTING
      field_ranges  = gt_field_ranges
    IMPORTING
      where_clauses = lt_where
    EXCEPTIONS
      OTHERS        = 1.
  IF sy-subrc <> 0.
    PERFORM log USING 'FREE_SELECTIONS_RANGE_2_WHERE could not convert the ranges'.
    RETURN.
  ENDIF.
  LOOP AT lt_where INTO DATA(ls_where).
    LOOP AT ls_where-where_tab INTO DATA(ls_line).
      lv_message = |Converted WHERE { ls_where-tablename }: { ls_line-line }|.
      PERFORM log USING lv_message.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

* Dropping the selection id makes the next dialog call build a fresh dynamic
* selection from the initial field list.
FORM reset_free_selections.
  CLEAR: gv_selection_id, gt_free_fields, gt_field_ranges,
         gs_expressions, gt_log, gv_active.
  PERFORM log USING 'Dynamic selection, field list, and result log reset'.
ENDFORM.
