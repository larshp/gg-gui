REPORT zgg_gui_sel_layout.

TYPE-POOLS icon.
TABLES sscrfields.

SELECTION-SCREEN FUNCTION KEY 1.

SELECTION-SCREEN BEGIN OF BLOCK b_main WITH FRAME TITLE g_title.
  SELECTION-SCREEN COMMENT /1(70) g_intro.
  SELECTION-SCREEN ULINE /1(70).
  SELECTION-SCREEN SKIP.
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(18) g_label FOR FIELD p_name.
    SELECTION-SCREEN POSITION 22.
    PARAMETERS p_name TYPE c LENGTH 20 LOWER CASE.
    SELECTION-SCREEN POSITION 50.
    SELECTION-SCREEN PUSHBUTTON (20) g_reset USER-COMMAND reset.
  SELECTION-SCREEN END OF LINE.
  PARAMETERS p_count TYPE i DEFAULT 1.
SELECTION-SCREEN END OF BLOCK b_main.

INITIALIZATION.
  g_title = 'Layout Elements'.
  g_intro = 'Comments, lines, positions, pushbuttons, and function keys'.
  g_label = 'Name'.
  WRITE icon_refresh AS ICON TO g_reset.
  g_reset+4 = ' Reset'.

  sscrfields-functxt_01-icon_id = icon_information.
  sscrfields-functxt_01-icon_text = 'About'.
  sscrfields-functxt_01-quickinfo = 'About this selection-screen sample'.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'RESET'.
      CLEAR p_name.
      p_count = 1.
      MESSAGE 'Selection values reset' TYPE 'S'.
    WHEN 'FC01'.
      MESSAGE 'Blocks, lines, comments, buttons, and function keys'
        TYPE 'I'.
  ENDCASE.

START-OF-SELECTION.
  WRITE: / 'Name:', p_name,
         / 'Count:', p_count.
