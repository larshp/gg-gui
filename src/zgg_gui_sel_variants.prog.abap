REPORT zgg_gui_sel_variants LINE-SIZE 132 LINE-COUNT 40.

TYPE-POOLS icon.

* Report variants are stored objects. Only variants whose name starts with the
* sample prefix GG_ may be created or deleted here, and only after an explicit
* confirmation. The variant and RSPARAMS API is missing from open-abap and is
* therefore isolated in the static include ZGG_NATIVE_SEL_VARIANTS.
CONSTANTS gc_prefix TYPE c LENGTH 3 VALUE 'GG_'.

TYPES ty_log_line TYPE c LENGTH 120.
TYPES ty_log TYPE STANDARD TABLE OF ty_log_line WITH EMPTY KEY.

DATA gv_category TYPE c LENGTH 20.
DATA gt_log TYPE ty_log.

PARAMETERS p_name TYPE c LENGTH 20 LOWER CASE DEFAULT 'Sample selection'.
PARAMETERS p_date TYPE d DEFAULT sy-datum.
PARAMETERS p_limit TYPE i DEFAULT 25.
PARAMETERS p_flag AS CHECKBOX DEFAULT 'X'.
SELECT-OPTIONS s_cat FOR gv_category.

SELECTION-SCREEN SKIP.
PARAMETERS p_vari TYPE c LENGTH 14 DEFAULT 'GG_SAMPLE'.
SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN PUSHBUTTON (22) g_show USER-COMMAND show.
  SELECTION-SCREEN POSITION 25.
  SELECTION-SCREEN PUSHBUTTON (22) g_save USER-COMMAND save.
  SELECTION-SCREEN POSITION 49.
  SELECTION-SCREEN PUSHBUTTON (22) g_del USER-COMMAND delete.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN PUSHBUTTON (22) g_subtab USER-COMMAND subtab.
  SELECTION-SCREEN POSITION 25.
  SELECTION-SCREEN PUSHBUTTON (22) g_subvar USER-COMMAND subvar.
  SELECTION-SCREEN POSITION 49.
  SELECTION-SCREEN PUSHBUTTON (22) g_subscr USER-COMMAND subscr.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN COMMENT /1(78) g_status.

INITIALIZATION.
  g_status = 'Save or read a GG_ variant, or start another report with values'.
  WRITE icon_display AS ICON TO g_show.
  g_show+4 = ' Read variant'.
  WRITE icon_create AS ICON TO g_save.
  g_save+4 = ' Save variant'.
  WRITE icon_delete AS ICON TO g_del.
  g_del+4 = ' Delete variant'.
  WRITE icon_execute_object AS ICON TO g_subtab.
  g_subtab+4 = ' SUBMIT values'.
  WRITE icon_execute_object AS ICON TO g_subvar.
  g_subvar+4 = ' SUBMIT variant'.
  WRITE icon_next_object AS ICON TO g_subscr.
  g_subscr+4 = ' SUBMIT screen'.
  s_cat[] = VALUE #( ( sign = 'I' option = 'EQ' low = 'Input' ) ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_vari.
  PERFORM variant_value_request.

AT SELECTION-SCREEN.
  CASE sy-ucomm.
    WHEN 'SHOW'.
      PERFORM show_variant_contents.
    WHEN 'SAVE'.
      PERFORM save_sample_variant.
    WHEN 'DELETE'.
      PERFORM delete_sample_variant.
    WHEN 'SUBTAB'.
      PERFORM submit_with_selection_table.
    WHEN 'SUBVAR'.
      PERFORM submit_using_variant.
    WHEN 'SUBSCR'.
      PERFORM submit_via_selection_screen.
  ENDCASE.

START-OF-SELECTION.
  FORMAT COLOR COL_HEADING INTENSIFIED ON.
  WRITE: / 'ZGG_GUI_SEL_VARIANTS - selection variants and report calls'.
  FORMAT RESET.
  ULINE.
  WRITE: / 'Variant', 22 p_vari,
         / 'Name', 22 p_name,
         / 'Date', 22 p_date,
         / 'Limit', 22 p_limit,
         / 'Flag', 22 p_flag.
  LOOP AT s_cat INTO DATA(ls_range).
    WRITE: / 'Category range', 22 ls_range-sign, 26 ls_range-option,
             31 ls_range-low, 54 ls_range-high.
  ENDLOOP.
  SKIP.
  WRITE: / icon_information AS ICON,
    'Variants started with USING SELECTION-SET are read by the called report itself.'.
  SKIP.
  FORMAT COLOR COL_HEADING.
  WRITE: / 'Result log'.
  FORMAT RESET.
  ULINE.
  IF gt_log IS INITIAL.
    WRITE: / 'No variant action has been performed yet'.
  ENDIF.
  LOOP AT gt_log INTO DATA(lv_line).
    WRITE: / lv_line.
  ENDLOOP.

FORM log USING iv_text TYPE string.
  APPEND iv_text TO gt_log.
  g_status = iv_text.
ENDFORM.

FORM confirm USING iv_question TYPE string
             CHANGING cv_confirmed TYPE abap_bool.
  DATA lv_answer TYPE c LENGTH 1.

  CLEAR cv_confirmed.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Sample variant'
      text_question         = iv_question
      text_button_1         = 'Continue'
      text_button_2         = 'Cancel'
      default_button        = '2'
      display_cancel_button = abap_false
    IMPORTING
      answer                = lv_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  cv_confirmed = xsdbool( sy-subrc = 0 AND lv_answer = '1' ).
ENDFORM.

FORM check_sample_variant CHANGING cv_allowed TYPE abap_bool.
  cv_allowed = xsdbool( p_vari CS gc_prefix AND p_vari(3) = gc_prefix ).
  IF cv_allowed = abap_false.
    PERFORM log USING 'Only variants with the GG_ sample prefix may be created or deleted'.
  ENDIF.
ENDFORM.

INCLUDE zgg_native_sel_variants.
