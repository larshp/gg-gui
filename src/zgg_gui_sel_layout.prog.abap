REPORT zgg_gui_sel_layout.

TYPE-POOLS icon.

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
  SELECTION-SCREEN SKIP.
  SELECTION-SCREEN PUSHBUTTON /1(20) g_about USER-COMMAND about.
SELECTION-SCREEN END OF BLOCK b_main.

INITIALIZATION.
  g_title = 'Layout Elements'.
  g_intro = 'Comments, lines, positions, and pushbuttons'.
  g_label = 'Name'.
  WRITE icon_refresh AS ICON TO g_reset.
  g_reset+4 = ' Reset'.
  WRITE icon_information AS ICON TO g_about.
  g_about+4 = ' About'.

AT SELECTION-SCREEN.
  CASE sy-ucomm.
    WHEN 'RESET'.
      CLEAR p_name.
      p_count = 1.
      MESSAGE 'Selection values reset' TYPE 'S'.
    WHEN 'ABOUT'.
      MESSAGE 'Blocks, lines, comments, positions, and buttons'
        TYPE 'I'.
  ENDCASE.

START-OF-SELECTION.
  WRITE: / 'Name:', p_name,
         / 'Count:', p_count.
