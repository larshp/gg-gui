REPORT zgg_gui_sel_fields.

DATA gt_list_values TYPE vrm_values.

PARAMETERS:
  p_text   TYPE c LENGTH 20 LOWER CASE OBLIGATORY DEFAULT 'Sample text',
  p_count  TYPE i DEFAULT 42,
  p_amount TYPE p LENGTH 8 DECIMALS 2 DEFAULT '19.95',
  p_date   TYPE d DEFAULT sy-datum,
  p_time   TYPE t DEFAULT sy-uzeit,
  p_check  AS CHECKBOX DEFAULT abap_true USER-COMMAND update,
  p_red    RADIOBUTTON GROUP color DEFAULT 'X',
  p_green  RADIOBUTTON GROUP color,
  p_blue   RADIOBUTTON GROUP color,
  p_list   TYPE c LENGTH 10 AS LISTBOX VISIBLE LENGTH 20,
  p_secret TYPE c LENGTH 20 LOWER CASE MODIF ID sec.

AT SELECTION-SCREEN OUTPUT.
  PERFORM populate_listbox.

  LOOP AT SCREEN.
    IF screen-group1 = 'SEC'.
      screen-invisible = '1'.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

START-OF-SELECTION.
  WRITE: / 'Text:', p_text,
         / 'Integer:', p_count,
         / 'Amount:', p_amount,
         / 'Date:', p_date,
         / 'Time:', p_time,
         / 'Checkbox:', p_check,
         / 'Radio group:', p_red, p_green, p_blue,
         / 'List box:', p_list,
         / 'Secret length:', strlen( p_secret ).

FORM populate_listbox.
  IF gt_list_values IS INITIAL.
    gt_list_values = VALUE #(
      ( key = 'STANDARD' text = 'Standard' )
      ( key = 'COMPACT' text = 'Compact' )
      ( key = 'DETAILED' text = 'Detailed' ) ).
  ENDIF.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_LIST'
      values = gt_list_values
    EXCEPTIONS
      OTHERS = 1.

  IF sy-subrc <> 0.
    MESSAGE 'The list box could not be populated' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
