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
    ( category = 'Container' program = 'ZGG_GUI_COMPOSITE'
      title = 'Workbench tree, grid, toolbar, and details' )
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
    ( category = 'Control' program = 'ZGG_GUI_TREE_MODELS'
      title = 'Simple, list, and column Tree Models' )
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
    ( category = 'ALV' program = 'ZGG_GUI_ALV_EVENTS'
      title = 'Grid events, extensions, and drag-drop' )
    ( category = 'ALV' program = 'ZGG_GUI_ALV_TREE'
      title = 'Hierarchical ALV nodes, state, and calculations' )
    ( category = 'ALV' program = 'ZGG_GUI_SALV_TREE'
      title = 'High-level SALV hierarchy and comparison' )
    ( category = 'ALV' program = 'ZGG_GUI_SALV_HIERSEQ'
      title = 'Two-level hierarchical-sequential SALV' )
    ( category = 'Frontend' program = 'ZGG_GUI_FRONTEND_SERVICES'
      title = 'Files, directories, clipboard, and capabilities' )
    ( category = 'Legacy' program = 'ZGG_GUI_CLASSIC_LIST'
      title = 'Classic interactive lists and spool behavior' )
    ( category = 'Frontend' program = 'ZGG_GUI_ILI_DRAGDROP'
      title = 'Interactive move, resize, and context menu' )
    ( category = 'Frontend' program = 'ZGG_GUI_DRAG_DROP'
      title = 'Tree, grid, and cross-control drag and drop' )
    ( category = 'Optional' program = 'ZGG_GUI_GRAPHICS'
      title = 'Installed graphics engines and color selector' )
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

* Every sample is submitted statically so the launcher stays free of dynamic
* program names; the branches mirror the catalog rows above.
  CASE gv_program.
    WHEN 'ZGG_GUI_CFW_BASICS'.
      SUBMIT zgg_gui_cfw_basics AND RETURN.
    WHEN 'ZGG_GUI_CUSTOM_CONTAINER'.
      SUBMIT zgg_gui_custom_container AND RETURN.
    WHEN 'ZGG_GUI_DOCKING_CONTAINER'.
      SUBMIT zgg_gui_docking_container AND RETURN.
    WHEN 'ZGG_GUI_SPLITTER_CONTAINER'.
      SUBMIT zgg_gui_splitter_container AND RETURN.
    WHEN 'ZGG_GUI_DIALOG_CONTAINER'.
      SUBMIT zgg_gui_dialog_container AND RETURN.
    WHEN 'ZGG_GUI_COMPOSITE'.
      SUBMIT zgg_gui_composite AND RETURN.
    WHEN 'ZGG_GUI_PICTURE'.
      SUBMIT zgg_gui_picture AND RETURN.
    WHEN 'ZGG_GUI_TEXTEDIT'.
      SUBMIT zgg_gui_textedit AND RETURN.
    WHEN 'ZGG_GUI_HTML_VIEWER'.
      SUBMIT zgg_gui_html_viewer AND RETURN.
    WHEN 'ZGG_GUI_ABAP_BROWSER'.
      SUBMIT zgg_gui_abap_browser AND RETURN.
    WHEN 'ZGG_GUI_TOOLBAR'.
      SUBMIT zgg_gui_toolbar AND RETURN.
    WHEN 'ZGG_GUI_CALENDAR'.
      SUBMIT zgg_gui_calendar AND RETURN.
    WHEN 'ZGG_GUI_TREES'.
      SUBMIT zgg_gui_trees AND RETURN.
    WHEN 'ZGG_GUI_TREE_MODELS'.
      SUBMIT zgg_gui_tree_models AND RETURN.
    WHEN 'ZGG_GUI_DYNAMIC_DOCUMENT'.
      SUBMIT zgg_gui_dynamic_document AND RETURN.
    WHEN 'ZGG_GUI_TIMER'.
      SUBMIT zgg_gui_timer AND RETURN.
    WHEN 'ZGG_GUI_SALV_TABLE'.
      SUBMIT zgg_gui_salv_table AND RETURN.
    WHEN 'ZGG_GUI_ALV_GRID'.
      SUBMIT zgg_gui_alv_grid AND RETURN.
    WHEN 'ZGG_GUI_ALV_DYNAMIC'.
      SUBMIT zgg_gui_alv_dynamic AND RETURN.
    WHEN 'ZGG_GUI_ALV_VARIANTS'.
      SUBMIT zgg_gui_alv_variants AND RETURN.
    WHEN 'ZGG_GUI_ALV_EDIT'.
      SUBMIT zgg_gui_alv_edit AND RETURN.
    WHEN 'ZGG_GUI_ALV_FORMAT'.
      SUBMIT zgg_gui_alv_format AND RETURN.
    WHEN 'ZGG_GUI_ALV_EVENTS'.
      SUBMIT zgg_gui_alv_events AND RETURN.
    WHEN 'ZGG_GUI_ALV_TREE'.
      SUBMIT zgg_gui_alv_tree AND RETURN.
    WHEN 'ZGG_GUI_SALV_TREE'.
      SUBMIT zgg_gui_salv_tree AND RETURN.
    WHEN 'ZGG_GUI_SALV_HIERSEQ'.
      SUBMIT zgg_gui_salv_hierseq AND RETURN.
    WHEN 'ZGG_GUI_FRONTEND_SERVICES'.
      SUBMIT zgg_gui_frontend_services AND RETURN.
    WHEN 'ZGG_GUI_CLASSIC_LIST'.
      SUBMIT zgg_gui_classic_list AND RETURN.
    WHEN 'ZGG_GUI_ILI_DRAGDROP'.
      SUBMIT zgg_gui_ili_dragdrop AND RETURN.
    WHEN 'ZGG_GUI_DRAG_DROP'.
      SUBMIT zgg_gui_drag_drop AND RETURN.
    WHEN 'ZGG_GUI_GRAPHICS'.
      SUBMIT zgg_gui_graphics AND RETURN.
    WHEN 'ZGG_GUI_SEL_FIELDS'.
      SUBMIT zgg_gui_sel_fields AND RETURN.
    WHEN 'ZGG_GUI_SEL_RANGES'.
      SUBMIT zgg_gui_sel_ranges AND RETURN.
    WHEN 'ZGG_GUI_SEL_LAYOUT'.
      SUBMIT zgg_gui_sel_layout AND RETURN.
    WHEN 'ZGG_GUI_SEL_DYNAMIC'.
      SUBMIT zgg_gui_sel_dynamic AND RETURN.
    WHEN 'ZGG_GUI_SEL_TABS'.
      SUBMIT zgg_gui_sel_tabs AND RETURN.
    WHEN 'ZGG_GUI_DYNPRO_ELEMENTS'.
      SUBMIT zgg_gui_dynpro_elements AND RETURN.
    WHEN 'ZGG_GUI_DYNPRO_FLOW'.
      SUBMIT zgg_gui_dynpro_flow AND RETURN.
    WHEN 'ZGG_GUI_TABLE_CONTROL'.
      SUBMIT zgg_gui_table_control AND RETURN.
    WHEN 'ZGG_GUI_TABSTRIP'.
      SUBMIT zgg_gui_tabstrip AND RETURN.
    WHEN 'ZGG_GUI_SUBSCREENS'.
      SUBMIT zgg_gui_subscreens AND RETURN.
    WHEN 'ZGG_GUI_DIALOGS_HELP'.
      SUBMIT zgg_gui_dialogs_help AND RETURN.
    WHEN 'ZGG_GUI_GUI_STATUS'.
      SUBMIT zgg_gui_gui_status AND RETURN.
    WHEN OTHERS.
      MESSAGE 'The selected program is not part of the catalog' TYPE 'S'.
  ENDCASE.
