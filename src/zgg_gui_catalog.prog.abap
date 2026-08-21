REPORT zgg_gui_catalog.

TYPES:
  BEGIN OF ty_sample,
    category TYPE c LENGTH 12,
    program  TYPE c LENGTH 40,
    title    TYPE c LENGTH 50,
  END OF ty_sample,
  ty_samples TYPE STANDARD TABLE OF ty_sample WITH EMPTY KEY.

DATA gt_samples TYPE ty_samples.
DATA gs_sample TYPE ty_sample.
DATA gv_program TYPE c LENGTH 40.

START-OF-SELECTION.
  gt_samples = VALUE #(
    ( category = 'Framework' program = 'ZGG_GUI_CFW_BASICS'
      title = 'Control Framework lifecycle' )
    ( category = 'Container' program = 'ZGG_GUI_CUSTOM_CONTAINER'
      title = 'Custom container hosts and lifetime' )
    ( category = 'Container' program = 'ZGG_GUI_DOCKING_CONTAINER'
      title = 'Docking edges, extension, and detachment' )
    ( category = 'Container' program = 'ZGG_GUI_SPLITTER_CONTAINER'
      title = 'Nested standard and easy splitter containers' )
    ( category = 'Container' program = 'ZGG_GUI_DIALOG_CONTAINER'
      title = 'Modeless dialog container lifecycle' )
    ( category = 'Control' program = 'ZGG_GUI_PICTURE'
      title = 'Picture sources and display modes' )
    ( category = 'Control' program = 'ZGG_GUI_TEXTEDIT'
      title = 'Text editing, state, selection, and files' )
    ( category = 'Control' program = 'ZGG_GUI_HTML_VIEWER'
      title = 'Generated HTML, navigation, and SAPEVENT' )
    ( category = 'Control' program = 'ZGG_GUI_ABAP_BROWSER'
      title = 'ABAP browser HTML and XML helper' )
    ( category = 'Control' program = 'ZGG_GUI_TOOLBAR'
      title = 'Toolbar buttons, menus, and events' )
    ( category = 'Control' program = 'ZGG_GUI_CALENDAR'
      title = 'Calendar selection and day information' )
    ( category = 'Control' program = 'ZGG_GUI_TREES'
      title = 'Column tree items, events, and mutations' )
    ( category = 'Control' program = 'ZGG_GUI_DYNAMIC_DOCUMENT'
      title = 'Dynamic Documents content and forms' )
    ( category = 'Control' program = 'ZGG_GUI_TIMER'
      title = 'Frontend timer lifecycle and refresh' )
    ( category = 'ALV' program = 'ZGG_GUI_SALV_TABLE'
      title = 'Read-only SALV table gallery' )
    ( category = 'ALV' program = 'ZGG_GUI_ALV_GRID'
      title = 'Basic ALV Grid state and variants' )
    ( category = 'ALV' program = 'ZGG_GUI_ALV_DYNAMIC'
      title = 'Dynamic output tables and styles' )
    ( category = 'ALV' program = 'ZGG_GUI_ALV_VARIANTS'
      title = 'Direct variant read, save, and cleanup' )
    ( category = 'ALV' program = 'ZGG_GUI_ALV_EDIT'
      title = 'Editable cells, validation, and row changes' )
    ( category = 'ALV' program = 'ZGG_GUI_ALV_FORMAT'
      title = 'Colors, styles, symbols, groups, and totals' )
    ( category = 'Selection' program = 'ZGG_GUI_SEL_FIELDS'
      title = 'Parameter field variants' )
    ( category = 'Selection' program = 'ZGG_GUI_SEL_RANGES'
      title = 'Select-options and ranges' )
    ( category = 'Selection' program = 'ZGG_GUI_SEL_LAYOUT'
      title = 'Selection-screen layout' )
    ( category = 'Selection' program = 'ZGG_GUI_SEL_DYNAMIC'
      title = 'Dynamic selection screens' )
    ( category = 'Selection' program = 'ZGG_GUI_SEL_TABS'
      title = 'Selection-screen subscreens and tabs' )
    ( category = 'Dynpro' program = 'ZGG_GUI_DYNPRO_ELEMENTS'
      title = 'Screen Painter element gallery' )
    ( category = 'Dynpro' program = 'ZGG_GUI_DYNPRO_FLOW'
      title = 'PBO, PAI, and dynamic field behavior' )
    ( category = 'Dynpro' program = 'ZGG_GUI_TABLE_CONTROL'
      title = 'Editable table control' )
    ( category = 'Dynpro' program = 'ZGG_GUI_TABSTRIP'
      title = 'Dynpro tabstrip control' )
    ( category = 'Dynpro' program = 'ZGG_GUI_SUBSCREENS'
      title = 'Reusable and dynamic subscreens' )
    ( category = 'Dynpro' program = 'ZGG_GUI_DIALOGS_HELP'
      title = 'Dialogs, messages, F1, and F4' )
    ( category = 'Dynpro' program = 'ZGG_GUI_GUI_STATUS'
      title = 'Menus, toolbars, function keys, and titles' ) ).

  FORMAT COLOR COL_HEADING INTENSIFIED ON.
  WRITE: / 'Category', 15 'Program', 58 'Sample'.
  FORMAT RESET.
  ULINE.

  LOOP AT gt_samples INTO gs_sample.
    gv_program = gs_sample-program.
    WRITE: / gs_sample-category,
             15 gs_sample-program HOTSPOT COLOR COL_KEY,
             58 gs_sample-title.
    HIDE gv_program.
  ENDLOOP.

AT LINE-SELECTION.
  IF gv_program IS INITIAL.
    MESSAGE 'Select a program name' TYPE 'S'.
    RETURN.
  ENDIF.

  SUBMIT (gv_program) AND RETURN.
