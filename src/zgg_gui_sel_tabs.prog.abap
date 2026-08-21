REPORT zgg_gui_sel_tabs.

TABLES sscrfields.

SELECTION-SCREEN BEGIN OF SCREEN 100 AS SUBSCREEN.
  SELECTION-SCREEN BEGIN OF BLOCK b_identity WITH FRAME TITLE g_idtit.
    PARAMETERS:
      p_name TYPE c LENGTH 30 LOWER CASE,
      p_role TYPE c LENGTH 20 LOWER CASE.
  SELECTION-SCREEN END OF BLOCK b_identity.
SELECTION-SCREEN END OF SCREEN 100.

SELECTION-SCREEN BEGIN OF SCREEN 200 AS SUBSCREEN.
  SELECTION-SCREEN BEGIN OF BLOCK b_contact WITH FRAME TITLE g_contit.
    PARAMETERS:
      p_email TYPE c LENGTH 40 LOWER CASE,
      p_phone TYPE c LENGTH 20.
  SELECTION-SCREEN END OF BLOCK b_contact.
SELECTION-SCREEN END OF SCREEN 200.

SELECTION-SCREEN BEGIN OF SCREEN 300 AS SUBSCREEN.
  SELECTION-SCREEN BEGIN OF BLOCK b_limits WITH FRAME TITLE g_limtit.
    PARAMETERS:
      p_limit TYPE i DEFAULT 25,
      p_active AS CHECKBOX DEFAULT abap_true.
  SELECTION-SCREEN END OF BLOCK b_limits.
SELECTION-SCREEN END OF SCREEN 300.

SELECTION-SCREEN BEGIN OF TABBED BLOCK g_tabs FOR 7 LINES.
  SELECTION-SCREEN TAB (20) g_tabid USER-COMMAND tab1
    DEFAULT SCREEN 100.
  SELECTION-SCREEN TAB (20) g_tabco USER-COMMAND tab2
    DEFAULT SCREEN 200.
  SELECTION-SCREEN TAB (20) g_tabli USER-COMMAND tab3
    DEFAULT SCREEN 300.
SELECTION-SCREEN END OF BLOCK g_tabs.

INITIALIZATION.
  g_idtit = 'Identity'.
  g_contit = 'Contact'.
  g_limtit = 'Limits'.
  g_tabid = 'Identity'.
  g_tabco = 'Contact'.
  g_tabli = 'Limits'.
  g_tabs-prog = sy-repid.
  g_tabs-dynnr = '0100'.
  g_tabs-activetab = 'TAB1'.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'TAB1'.
      g_tabs-dynnr = '0100'.
      g_tabs-activetab = 'TAB1'.
    WHEN 'TAB2'.
      g_tabs-dynnr = '0200'.
      g_tabs-activetab = 'TAB2'.
    WHEN 'TAB3'.
      g_tabs-dynnr = '0300'.
      g_tabs-activetab = 'TAB3'.
    WHEN 'ONLI'.
      CASE g_tabs-activetab.
        WHEN 'TAB1'.
          IF p_name IS INITIAL.
            SET CURSOR FIELD 'P_NAME'.
            MESSAGE 'Enter a name on the active Identity tab' TYPE 'E'.
          ENDIF.
        WHEN 'TAB2'.
          IF p_email IS INITIAL.
            SET CURSOR FIELD 'P_EMAIL'.
            MESSAGE 'Enter an email address on the active Contact tab' TYPE 'E'.
          ENDIF.
        WHEN 'TAB3'.
          IF p_limit <= 0.
            SET CURSOR FIELD 'P_LIMIT'.
            MESSAGE 'Limit must be greater than zero' TYPE 'E'.
          ENDIF.
      ENDCASE.
  ENDCASE.

START-OF-SELECTION.
  WRITE: / 'Name:', p_name,
         / 'Role:', p_role,
         / 'Email:', p_email,
         / 'Phone:', p_phone,
         / 'Limit:', p_limit,
         / 'Active:', p_active.
