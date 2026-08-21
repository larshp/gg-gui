REPORT zgg_gui_sel_ranges.

DATA gv_number TYPE i.

SELECT-OPTIONS:
  s_number FOR gv_number DEFAULT 10 TO 50,
  s_single FOR gv_number NO-EXTENSION NO INTERVALS,
  s_fixed  FOR gv_number DEFAULT 100 NO-EXTENSION,
  s_req    FOR gv_number OBLIGATORY.

INITIALIZATION.
  DATA ls_restriction TYPE sscr_restrict.
  DATA ls_option_list TYPE sscr_opt_list.
  DATA ls_assignment TYPE sscr_ass.

  ls_option_list-name = 'NUMBERS'.
  ls_option_list-options-eq = abap_true.
  ls_option_list-options-bt = abap_true.
  ls_option_list-options-ge = abap_true.
  ls_option_list-options-le = abap_true.
  APPEND ls_option_list TO ls_restriction-opt_list_tab.

  ls_assignment-kind = 'S'.
  ls_assignment-name = 'S_NUMBER'.
  ls_assignment-sg_main = 'I'.
  ls_assignment-sg_addy = 'E'.
  ls_assignment-op_main = 'NUMBERS'.
  ls_assignment-op_addy = 'NUMBERS'.
  APPEND ls_assignment TO ls_restriction-ass_tab.

  CALL FUNCTION 'SELECT_OPTIONS_RESTRICT'
    EXPORTING
      restriction            = ls_restriction
    EXCEPTIONS
      too_late               = 1
      repeated               = 2
      selopt_without_options = 3
      selopt_without_signs   = 4
      invalid_sign           = 5
      empty_option_list      = 6
      invalid_kind           = 7
      repeated_kind_a        = 8
      OTHERS                 = 9.

  IF sy-subrc <> 0.
    MESSAGE 'Select-option restrictions could not be applied'
      TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

START-OF-SELECTION.
  FORMAT COLOR COL_HEADING.
  WRITE: / 'Range', 14 'Sign', 21 'Option', 31 'Low', 48 'High'.
  FORMAT RESET.
  ULINE.

  LOOP AT s_number.
    WRITE: / 'S_NUMBER', 14 s_number-sign, 21 s_number-option,
             31 s_number-low, 48 s_number-high.
  ENDLOOP.
  LOOP AT s_single.
    WRITE: / 'S_SINGLE', 14 s_single-sign, 21 s_single-option,
             31 s_single-low, 48 s_single-high.
  ENDLOOP.
  LOOP AT s_fixed.
    WRITE: / 'S_FIXED', 14 s_fixed-sign, 21 s_fixed-option,
             31 s_fixed-low, 48 s_fixed-high.
  ENDLOOP.
  LOOP AT s_req.
    WRITE: / 'S_REQ', 14 s_req-sign, 21 s_req-option,
             31 s_req-low, 48 s_req-high.
  ENDLOOP.
