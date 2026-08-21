REPORT zgg_gui_sel_dynamic.

SELECTION-SCREEN BEGIN OF BLOCK b_options WITH FRAME TITLE g_opttit.
  PARAMETERS:
    p_enable AS CHECKBOX DEFAULT abap_true USER-COMMAND toggle,
    p_basic  RADIOBUTTON GROUP mode DEFAULT 'X' USER-COMMAND mode,
    p_adv    RADIOBUTTON GROUP mode.
SELECTION-SCREEN END OF BLOCK b_options.

SELECTION-SCREEN BEGIN OF BLOCK b_adv WITH FRAME TITLE g_advtit.
  PARAMETERS:
    p_req    TYPE c LENGTH 20 LOWER CASE MODIF ID adv,
    p_city   TYPE c LENGTH 20 LOWER CASE MODIF ID adv,
    p_secret TYPE c LENGTH 20 LOWER CASE MODIF ID sec,
    p_note   TYPE c LENGTH 30 LOWER CASE MODIF ID bsc.
SELECTION-SCREEN END OF BLOCK b_adv.

INITIALIZATION.
  g_opttit = 'Screen State'.
  g_advtit = 'Dynamic Fields'.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'ADV'.
        screen-active = COND #( WHEN p_adv = abap_true THEN '1' ELSE '0' ).
        IF screen-name = 'P_REQ' AND p_adv = abap_true.
          screen-required = '2'.
        ENDIF.
      WHEN 'SEC'.
        screen-invisible = '1'.
      WHEN 'BSC'.
        screen-intensified = COND #( WHEN p_basic = abap_true
                                     THEN '1' ELSE '0' ).
    ENDCASE.

    IF p_enable = abap_false AND screen-name <> 'P_ENABLE'.
      screen-input = '0'.
      screen-output = '1'.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.

AT SELECTION-SCREEN ON RADIOBUTTON GROUP mode.
  IF p_adv = abap_true AND p_enable = abap_false.
    MESSAGE 'Enable input before choosing advanced mode' TYPE 'E'.
  ENDIF.

AT SELECTION-SCREEN ON p_req.
  IF p_adv = abap_true AND p_req IS INITIAL.
    SET CURSOR FIELD 'P_REQ'.
    MESSAGE 'Required value is missing in advanced mode' TYPE 'E'.
  ENDIF.

AT SELECTION-SCREEN ON BLOCK b_adv.
  IF p_adv = abap_true AND strlen( p_secret ) BETWEEN 1 AND 3.
    SET CURSOR FIELD 'P_SECRET'.
    MESSAGE 'Secret must contain at least four characters' TYPE 'E'.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_city.
  TYPES:
    BEGIN OF ty_city,
      city    TYPE c LENGTH 20,
      country TYPE c LENGTH 3,
    END OF ty_city.
  DATA lt_cities TYPE STANDARD TABLE OF ty_city WITH EMPTY KEY.
  DATA lt_return TYPE STANDARD TABLE OF ddshretval WITH EMPTY KEY.
  DATA ls_return TYPE ddshretval.

  lt_cities = VALUE #(
    ( city = 'Berlin' country = 'DE' )
    ( city = 'Copenhagen' country = 'DK' )
    ( city = 'Prague' country = 'CZ' ) ).

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'CITY'
      value_org   = 'S'
    TABLES
      value_tab   = lt_cities
      return_tab  = lt_return
    EXCEPTIONS
      parameter_error        = 1
      no_values_found        = 2
      OTHERS                 = 3.

  IF sy-subrc = 0.
    READ TABLE lt_return INTO ls_return INDEX 1.
    IF sy-subrc = 0.
      p_city = ls_return-fieldval.
    ENDIF.
  ENDIF.

AT SELECTION-SCREEN ON HELP-REQUEST FOR p_note.
  MESSAGE 'This field demonstrates custom F1 help' TYPE 'I'.

START-OF-SELECTION.
  WRITE: / 'Input enabled:', p_enable,
         / 'Basic mode:', p_basic,
         / 'Advanced mode:', p_adv,
         / 'Required value:', p_req,
         / 'City:', p_city,
         / 'Note:', p_note.
