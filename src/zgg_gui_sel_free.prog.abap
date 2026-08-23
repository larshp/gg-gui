REPORT zgg_gui_sel_free LINE-SIZE 132 LINE-COUNT 40.

TYPE-POOLS icon.

* Free selections are the dynamic-selection dialog known from logical-database
* reports. The dialog is built from DDIC metadata of the fields offered to the
* user; this sample offers three fields of the message text table and displays
* the generated ranges and WHERE clause instead of reading any data.
* The RSDS* type family and the FREE_SELECTIONS_* function modules are missing
* from open-abap, so they are isolated in the include ZGG_NATIVE_SEL_FREE.

TYPES ty_log_line TYPE c LENGTH 120.
TYPES ty_log TYPE STANDARD TABLE OF ty_log_line WITH EMPTY KEY.

DATA gt_log TYPE ty_log.
DATA gv_active TYPE i.

SELECTION-SCREEN COMMENT /1(78) g_intro.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN PUSHBUTTON (24) g_window USER-COMMAND dlgwin.
  SELECTION-SCREEN POSITION 27.
  SELECTION-SCREEN PUSHBUTTON (24) g_full USER-COMMAND dlgfull.
  SELECTION-SCREEN POSITION 53.
  SELECTION-SCREEN PUSHBUTTON (24) g_reset USER-COMMAND reset.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN COMMENT /1(78) g_status.

INITIALIZATION.
  g_intro = 'Dynamic selections built with FREE_SELECTIONS_INIT and _DIALOG'.
  g_status = 'No dynamic selection has been entered yet'.
  WRITE icon_display AS ICON TO g_window.
  g_window+4 = ' Dialog window'.
  WRITE icon_display_more AS ICON TO g_full.
  g_full+4 = ' Fullscreen dialog'.
  WRITE icon_refresh AS ICON TO g_reset.
  g_reset+4 = ' Reset selection'.

AT SELECTION-SCREEN.
  CASE sy-ucomm.
    WHEN 'DLGWIN'.
      PERFORM open_free_selections USING abap_true.
    WHEN 'DLGFULL'.
      PERFORM open_free_selections USING abap_false.
    WHEN 'RESET'.
      PERFORM reset_free_selections.
  ENDCASE.

START-OF-SELECTION.
  FORMAT COLOR COL_HEADING INTENSIFIED ON.
  WRITE: / 'ZGG_GUI_SEL_FREE - dynamic selections'.
  FORMAT RESET.
  ULINE.
  WRITE: / 'Active dynamic selection fields', 40 gv_active.
  SKIP.
  WRITE: / icon_information AS ICON,
    'The generated range table and WHERE clause are displayed only; no data is read.'.
  SKIP.
  FORMAT COLOR COL_HEADING.
  WRITE: / 'Dynamic selection result'.
  FORMAT RESET.
  ULINE.
  IF gt_log IS INITIAL.
    WRITE: / 'Open the dialog on the selection screen before executing the report'.
  ENDIF.
  LOOP AT gt_log INTO DATA(lv_line).
    WRITE: / lv_line.
  ENDLOOP.

FORM log USING iv_text TYPE string.
  APPEND iv_text TO gt_log.
  g_status = iv_text.
ENDFORM.

INCLUDE zgg_native_sel_free.
