# Transpiler and Runtime Anomalies

Record differences between native SAP behavior and the open-abap transpiler or
runtime here. Also record SAP APIs needed by a sample that are missing or only
partially implemented in open-abap.

Do not record ordinary sample defects, SAP release differences, unsupported SAP
GUI frontend features, or local development-environment failures in this file.


## Entry Template

### Short title

- Status: Open, confirmed, reported, fixed, or accepted limitation
- Sample: `ZGG_GUI_*`
- Component: Transpiler, runtime, `open-abap-core`, or `open-abap-gui`
- Version or commit: Exact tested version or commit
- Native SAP behavior: What happens on the declared SAP baseline
- open-abap behavior: What happens under transpilation or at runtime
- Reproduction: Minimal commands and source needed to reproduce it
- Workaround: Current workaround, or `None`
- Upstream reference: Issue or pull request URL, or `Not reported`

## Recorded Anomalies

### `CL_CTMENU` has a partial API and no runtime behavior

- Status: Open, confirmed
- Sample: `ZGG_GUI_GUI_STATUS`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_CTMENU` can add functions, separators, and submenus;
  enable, disable, show, or hide functions; load a Menu Painter status; and mark
  a default function. A dynpro `ON_CTMENU_*` callback produces an interactive
  context menu.
- open-abap behavior: `SET_DEFAULT_FUNCTION`, `LOAD_GUI_STATUS`,
  `DISABLE_FUNCTIONS`, `ENABLE_FUNCTIONS`, and other public native methods are
  absent from the class definition. The currently declared methods used by the
  sample, including `ADD_FUNCTION`, `ADD_SEPARATOR`, and `ADD_SUBMENU`, have
  empty implementations and therefore do not construct a runtime menu.
- Reproduction: Add
  `io_menu->set_default_function( fcode = 'APPLY' ).` where `io_menu` is typed
  as `REF TO cl_ctmenu`, then run `npm test`. abaplint reports method
  `SET_DEFAULT_FUNCTION` as missing. The empty implementations can be seen in
  `src/cl_ctmenu.clas.abap` at the commit above.
- Workaround: Omit the default-function marker so the native SAP sample remains
  type-compatible with the available open-abap surface. Treat context-menu
  behavior as native-SAP-only until the runtime methods are implemented.
- Upstream reference: Not reported

### Core Control Framework classes are runtime stubs

- Status: Open, confirmed
- Sample: `ZGG_GUI_CFW_BASICS`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: Creating a custom container, text edit, or timer creates
  frontend controls. Control state methods queue automation calls; CFW dispatch,
  flush, focus, update, and timer methods coordinate real SAP GUI state and
  events.
- open-abap behavior: Key constructors and methods are placeholders. For
  example, `CL_GUI_CUSTOM_CONTAINER->CONSTRUCTOR`,
  `CL_GUI_TEXTEDIT->CONSTRUCTOR`, `CL_GUI_TIMER->RUN`,
  `CL_GUI_CFW=>DISPATCH`, `SET_NEW_OK_CODE`, `UPDATE_VIEW`, and control focus or
  enablement methods execute unconditional failed assertions. The native
  `CL_GUI_CONTROL` constants `LIFETIME_DEFAULT`, `LIFETIME_DYNPRO`, and
  `LIFETIME_IMODE` are absent from the open-abap class definition. Many
  remaining control methods return without maintaining state, and metric
  conversion always returns `1`.
- Reproduction: Transpile and execute `ZGG_GUI_CFW_BASICS`, or minimally create
  `CL_GUI_CUSTOM_CONTAINER` with a container name. The constructor reaches
  `ASSERT 1 = 2` in `src/cl_gui_custom_container.clas.abap` at the commit above.
- Workaround: None for runtime GUI behavior. The samples are retained for
  native SAP and can currently be syntax-checked against the open-abap type
  surface. `ZGG_GUI_CUSTOM_CONTAINER` gives the three lifetime modes local,
  named constants with their native values `0`, `1`, and `2`.
- Upstream reference: Not reported

### Native container classes are declared but have no runtime behavior

- Status: Open, confirmed
- Sample: `ZGG_GUI_DOCKING_CONTAINER`, `ZGG_GUI_SPLITTER_CONTAINER`, and
  `ZGG_GUI_DIALOG_CONTAINER`
- Component: `open-abap-gui`
- Version or commit: `08bd747` (`open-abap-gui` local checkout, 2026-08-23);
  originally recorded against `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
- Native SAP behavior: `CL_GUI_DOCKING_CONTAINER` docks a child control on any
  screen edge and can float it; `CL_GUI_EASY_SPLITTER_CONTAINER` divides a
  parent into two cells; and `CL_GUI_DIALOGBOX_CONTAINER` creates a modeless
  dialog with close and resize events.
- open-abap behavior: `CL_GUI_DOCKING_CONTAINER`, `CL_GUI_DIALOGBOX_CONTAINER`,
  and `CL_GUI_EASY_SPLITTER_CONTAINER` are now declared with their native
  constructor, `DOCK_AT`, `SET_EXTENSION`, `FLOAT`, `SET_CAPTION`, `CLOSE`
  event, and inner-container attributes, so static code resolves. Every
  method body
  returns without creating a frontend control, and the easy-splitter
  `TOP_LEFT_CONTAINER` / `BOTTOM_RIGHT_CONTAINER` attributes stay unbound.
  `CL_GUI_SPLITTER_CONTAINER` still has no minimum-size API in native SAP
  either, so no such call can be written statically at all.
- Reproduction: Construct `CL_GUI_EASY_SPLITTER_CONTAINER` with a valid parent
  and inspect `TOP_LEFT_CONTAINER`; it remains initial because the constructor
  returns immediately.
- Workaround: The reports declare the containers statically and guard
  construction, so all three remain syntax checked. Interactive docking,
  dialog-box, and easy-splitter behavior cannot run under open-abap.
- Upstream reference: Not reported

### `CL_GUI_CALENDAR` event-ID constants are missing and its runtime is stubbed

- Status: Open, confirmed
- Sample: `ZGG_GUI_CALENDAR`
- Component: `open-abap-gui`
- Version or commit: `08bd747` (`open-abap-gui` local checkout, 2026-08-23);
  originally recorded against `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
- Native SAP behavior: `CL_GUI_CALENDAR` displays localized calendar views,
  selects single dates or ranges, supplies date-selection and information
  events, and attaches colors and tooltip text to dates.
- open-abap behavior: `CL_GUI_CALENDAR` and the `CNCA` type pool are now
  declared, covering the native constructor, `GO_TO_DATE`, `SET_SELECTION`,
  `GET_SELECTION`, `SET_DAY_INFO`, `RESET_DAY_INFO`, `RESET_SELECTION`, and the
  `DATE_SELECTED` / `INFO_REQUEST` events, so the sample is statically checked. All method bodies return without
  frontend state. The `M_ID_DATE_SELECTED` and `M_ID_INFO_REQUEST` event-ID
  constants required by `SET_REGISTERED_EVENTS` are still absent.
- Reproduction: Reference `cl_gui_calendar=>m_id_date_selected` in a checked
  report and run `npm test`; abaplint reports the constant as not found. Calling
  `GET_SELECTION` returns initial dates because the body returns immediately.
- Workaround: `ZGG_GUI_CALENDAR` declares the control statically and guards
  construction. Static include `ZGG_NATIVE_CALENDAR` declares handlers for
  `DATE_SELECTED` and `INFO_REQUEST`, registers the native event IDs, returns
  event ranges through ABAP memory, and deregisters before recreation or exit.
  Day-info fixtures use the native `CNCA_ITAB_DAY_INFO` type. Because the
  event-ID constants are still missing, lint issue reporting stays disabled for
  this native include; activation and event behavior remain native-SAP checks.
- Upstream reference: Not reported

### The Dynamic Documents API is partial and its runtime behavior is stubbed

- Status: Open, confirmed
- Sample: `ZGG_GUI_DYNAMIC_DOCUMENT`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_DD_DOCUMENT` and its `CL_DD_AREA`, table, form,
  link, button, input, and select element classes build an HTML-backed Dynamic
  Document. Native applications can display the document in a GUI container,
  register element events, refresh retained elements, and print it.
- open-abap behavior: `src/dd` now declares the full element family used by the
  sample, including `CL_DD_LINK_ELEMENT`, `CL_DD_SELECT_ELEMENT`, `ADD_LINK`,
  `ADD_SELECT_ELEMENT`, the `SDYDO_OPTION_TAB` option type, and the `CLICKED`,
  `ENTERED`, `HELP_F1`, and `SELECTED` element events. Every method body still
  returns without constructing HTML or element objects, so `VERTICAL_SPLIT`
  leaves `RIGHT_AREA` unbound and `ADD_FORM` leaves `FORMAREA` unbound. The
  `NAME` attribute of `CL_DD_INPUT_ELEMENT` and the `VALUE` attribute of
  `CL_DD_SELECT_ELEMENT`, both read by the event handlers, are still absent.
- Reproduction: Create `CL_DD_DOCUMENT`, call `VERTICAL_SPLIT`, and inspect the
  exported `RIGHT_AREA`; it remains initial because the implementation returns
  immediately. Reference `input_element->name` in a checked report and run
  `npm test`; abaplint reports the attribute as not found.
- Workaround: `ZGG_GUI_DYNAMIC_DOCUMENT` declares every element statically and,
  if the document returns no child areas, displays an HTML fallback through
  `CL_GUI_HTML_VIEWER`. Static include `ZGG_NATIVE_DOCUMENT` declares typed
  handlers for link/button `CLICKED`, input `ENTERED`/`HELP_F1`, and select
  `SELECTED`, returns the sender name and current value through ABAP memory, and
  deregisters before reset or exit. Because the two element attributes are still
  missing, lint issue reporting stays disabled for this native include;
  activation and event behavior remain native-SAP checks.
- Upstream reference: Not reported

### Tree control coverage is partial and runtime methods are stubbed

- Status: Open, confirmed
- Sample: `ZGG_GUI_TREES`, `ZGG_GUI_TREE_MODELS`, and `ZGG_GUI_ALV_TREE`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: SAP provides simple, list, and column tree controls plus
  corresponding backend tree-model classes. Column trees create frontend
  nodes and items, retain selection and expansion state, raise item and header
  events, and support node mutation and drag-and-drop.
- open-abap behavior: The repository declares `CL_GUI_COLUMN_TREE`,
  `CL_TREE_CONTROL_BASE`, `CL_ITEM_TREE_CONTROL`, and ALV tree classes. The
  column-tree constructor and core transfer methods fail assertions, while
  most inherited state methods return without behavior. `MOVE_NODE` and the
  backend model classes `CL_TREE_MODEL`, `CL_ITEM_TREE_MODEL`,
  `CL_SIMPLE_TREE_MODEL`, `CL_LIST_TREE_MODEL`, and `CL_COLUMN_TREE_MODEL` are
  now declared, together with the `MTREE*` node/item structures and the
  `TREEMSNOTA` / `TREEMLNOTA` / `TREEMCNOTA` / `TREEMLITAC` / `TREEMCITAC`
  table types; every model method body returns without behavior.
  `CL_GUI_SIMPLE_TREE` and `CL_GUI_LIST_TREE` remain absent. The ALV tree
  constructor and core display/node/state methods are assertion stubs or
  no-ops, and its native `NODE_CONTEXT_MENU_REQUEST` event is still not
  declared even though context-menu selection is present.
- Reproduction: Create `CL_GUI_COLUMN_TREE` with a valid parent and hierarchy
  header; the constructor reaches `ASSERT 1 = 'todo'` in
  `src/cl_gui_column_tree.clas.abap`. A static reference to
  `CL_GUI_SIMPLE_TREE` still fails abaplint type resolution.
- Workaround: `ZGG_GUI_TREES` catches construction failures and shows a text
  fallback; `ZGG_GUI_TREE_MODELS` declares each model class statically and keeps
  a shared `CL_TREE_MODEL` reference for the lifecycle calls. The class-audit
  action reports which GUI and model variants exist on the current system.
  Static include `ZGG_NATIVE_ALV_TREE` declares a typed handler for the missing
  native `NODE_CONTEXT_MENU_REQUEST`, preserves the tree's existing frontend
  event registrations, adds two menu commands, and deregisters the handler on
  exit. Because that event and two `CL_CTMENU` methods are still missing, lint
  issue reporting stays disabled for this native include; activation and event
  behavior remain native-SAP checks.
- Upstream reference: Not reported

### SALV table API is declared but core runtime behavior is stubbed

- Status: Open, confirmed
- Sample: `ZGG_GUI_SALV_TABLE`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_SALV_TABLE=>FACTORY` builds fullscreen, popup, list,
  or container-based read-only ALV output. Its column, function, sort, filter,
  aggregation, layout, selection, event, hyperlink, form, refresh, offline, and
  XML APIs configure and interrogate the displayed table.
- open-abap behavior: The SALV classes and many supporting DDIC types are
  declared, but `CL_SALV_TABLE=>FACTORY`, `DISPLAY`, `GET_COLUMNS`,
  `GET_FUNCTIONS`, selection, layout, sorting, aggregation, offline, refresh,
  popup, and `TO_XML` methods fail unconditional assertions. Other methods,
  including filters, hyperlinks, display settings, and individual function
  toggles, return without retaining state. `CL_SALV_FORM_LAYOUT_GRID` and its
  `CL_SALV_FORM_HEADER_INFO` / `CL_SALV_FORM_LABEL` results are now declared,
  but their bodies return without building a form element.
- Reproduction: Call `CL_SALV_TABLE=>FACTORY` with any internal table; the
  implementation reaches `ASSERT 1 = 'todo'` in
  `src/salv/cl_salv_table.clas.abap`. The other placeholder implementations are
  in `src/salv` at the commit above.
- Workaround: `ZGG_GUI_SALV_TABLE` catches construction failures and displays a
  read-only text fallback. Every column, function, and form call is declared
  statically and syntax checked. There is no workaround for executing an
  interactive SALV table in the current runtime.
- Upstream reference: Not reported

### ALV Grid API is mostly nonfunctional at runtime

- Status: Open, confirmed
- Sample: `ZGG_GUI_ALV_GRID` and `ZGG_GUI_ALV_FORMAT`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_GUI_ALV_GRID` displays a stable output table from an
  LVC field catalog and retains frontend layout, selection, current-cell,
  scroll, sort, filter, subtotal, print, and variant state. It supports soft
  refresh, standard export, title and input-state changes, and a configurable
  Control Framework border.
- open-abap behavior: The class declares most of the native surface used by the
  sample, but its constructor, initial display, refresh, selection, frontend
  layout, ready-for-input, and offline methods fail unconditional assertions.
  Most remaining getters, setters, criteria, variant, print, subtotal, command,
  and scroll methods return without storing or returning state. Function-code
  constants that drive the standard toolbar are declared with placeholder
  value `TODO` rather than their native values.
- Reproduction: Instantiate `CL_GUI_ALV_GRID` with a container; the constructor
  reaches `ASSERT 1 = 'todo'` in `src/cl_gui_alv_grid.clas.abap`. The no-op
  implementations and placeholder constants are in the same file at the
  tested commit.
- Workaround: `ZGG_GUI_ALV_GRID` catches construction failure and presents a
  read-only text fallback. Its native SAP calls remain statically checked
  against the available class and LVC DDIC declarations; interactive ALV Grid
  behavior cannot currently run under open-abap.
- Upstream reference: Not reported

### Dynamic ALV table creation is an assertion stub

- Status: Open, confirmed
- Sample: `ZGG_GUI_ALV_DYNAMIC`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_ALV_TABLE_CREATE=>CREATE_DYNAMIC_TABLE` turns an LVC
  field catalog into a referenced standard table. With `I_STYLE_TABLE`, it also
  adds a generated `LVC_T_STYL` component and returns that component name so
  callers can populate cell styles generically before displaying the table in
  `CL_GUI_ALV_GRID`.
- open-abap behavior: The class and method signature exist under `src/alv`, but
  the implementation consists only of `ASSERT 1 = 2`. It cannot return a table
  reference or style-field name. The generated `LVC_S_STYL` and `LVC_T_STYL`
  DDIC artifacts are now present, so the style component can be typed
  statically even though the factory cannot produce one.
- Reproduction: Call `CL_ALV_TABLE_CREATE=>CREATE_DYNAMIC_TABLE` with a valid
  `LVC_T_FCAT`; execution reaches the failed assertion in
  `src/alv/cl_alv_table_create.clas.abap`.
- Workaround: `ZGG_GUI_ALV_DYNAMIC` catches factory failure and displays a text
  fallback. All post-creation population uses generic field symbols, including
  generic access to the generated style table, so no replacement SAP DDIC type
  is introduced solely for open-abap.
- Upstream reference: Not reported

### Direct ALV variant methods do not retain or persist state

- Status: Open, confirmed
- Sample: `ZGG_GUI_ALV_VARIANTS`
- Component: `open-abap-gui`
- Version or commit: `08bd747` (`open-abap-gui` local checkout, 2026-08-23);
  originally recorded against `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
- Native SAP behavior: `CL_ALV_VARIANT` binds an output table, LVC field
  catalog, layout, and `DISVARIANT` key; it reads stored field catalogs and can
  delete a supplied set of layout variants. The owning grid applies, saves, and
  switches variants for the same report and handle.
- open-abap behavior: `CL_ALV_VARIANT` is declared under `src/alv`, but its
  constructor, `GET_VARIANT_INFO_FROM_DB`, and `DELETE_VARIANTS` all return
  without retaining state, reading storage, or deleting anything. The related
  `CL_GUI_ALV_GRID` variant methods are also no-ops. `DELETE_VARIANTS` takes
  `LTVARIANTS`, the full LTDX layout record, rather than a table of the
  `DISVARIANT` key structure the grid and the sample otherwise work with.
- Reproduction: Construct `CL_ALV_VARIANT`, call
  `GET_VARIANT_INFO_FROM_DB`, and inspect `ET_FCAT`; it remains initial because
  the implementation immediately returns in
  `src/alv/cl_alv_variant.clas.abap`.
- Workaround: The sample remains native-SAP-only for persistence. It tracks
  only successfully saved `GG_` keys for its own report and `GGV1` handle,
  requires explicit confirmation, and supplies only those tracked keys to
  `DELETE_VARIANTS`, mapping them onto `LTVARIANTS` rows first.
- Upstream reference: Not reported

### Editable ALV and changed-data protocol behavior is stubbed

- Status: Open, confirmed
- Sample: `ZGG_GUI_ALV_EDIT`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: An editable `CL_GUI_ALV_GRID` raises `DATA_CHANGED`,
  `DATA_CHANGED_FINISHED`, button, and custom F4 events. Its
  `CL_ALV_CHANGED_DATA_PROTOCOL` supplies modified-cell tables, validation
  messages, cell and style changes, value lookup, refresh, and a protocol
  display.
- open-abap behavior: The event declarations and protocol data attributes are
  available, but the grid constructor and edit registration path are
  nonfunctional. Protocol `ADD_PROTOCOL_ENTRY`, `GET_CELL_VALUE`,
  `MODIFY_CELL`, and `DISPLAY_PROTOCOL` fail assertions; construction,
  `MODIFY_STYLE`, and `REFRESH_PROTOCOL` return without state changes. The
  `LVC_S_STYL` and `LVC_T_STYL` DDIC artifacts are now present.
- Reproduction: Construct `CL_ALV_CHANGED_DATA_PROTOCOL` and call
  `ADD_PROTOCOL_ENTRY`; execution reaches `ASSERT 1 = 'todo'` in
  `src/alv/cl_alv_changed_data_protocol.clas.abap`.
- Workaround: The report is native-SAP-only for editing and validation. Its
  output row now carries a real `LVC_T_STYL` style component, and it catches
  grid construction failure before any interactive edit path runs.
- Upstream reference: Not reported

### ALV delayed-selection callback is missing and event helpers are no-ops

- Status: Open, confirmed
- Sample: `ZGG_GUI_ALV_EVENTS`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_GUI_ALV_GRID` raises interaction, toolbar, menu,
  context, help, drag/drop, subtotal, print, and delayed-selection callbacks.
  `CL_DRAGDROP` assigns a usable handle, and system versus application events
  follow different Control Framework delivery paths.
- open-abap behavior: The grid declares most events, but omits the native
  `DELAYED_CHANGED_SEL_CALLBACK` event while retaining
  `REGISTER_DELAYED_EVENT` and its event ID. Grid construction and event helper
  methods are assertion stubs or no-ops. `CL_DRAGDROP->ADD`, `GET`, and
  `GET_HANDLE` return without creating registrations, and
  `CL_DRAGDROPOBJECT->ABORT` is a no-op.
- Reproduction: Declare a handler `FOR EVENT DELAYED_CHANGED_SEL_CALLBACK OF
  CL_GUI_ALV_GRID` and run `npm test`; abaplint reports that the event does not
  exist. Inspect the grid and drag/drop implementations at the tested commit
  for the placeholder bodies.
- Workaround: Static include `ZGG_NATIVE_ALV_EVENTS` declares a typed handler
  for the missing callback, registers `MC_EVT_DELAYED_CHANGE_SELECT`, preserves
  the handler across application/system event-mode recreation, and deregisters
  it before freeing the grid. Lint issue reporting is disabled only for this
  native include; activation and event behavior remain native-SAP checks. Grid
  construction stays guarded with a text fallback under open-abap.
- Upstream reference: Not reported

### SALV tree class family is declared but has no runtime behavior

- Status: Open, confirmed
- Sample: `ZGG_GUI_SALV_TREE`
- Component: `open-abap-gui`
- Version or commit: `08bd747` (`open-abap-gui` local checkout, 2026-08-23);
  originally recorded against `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
- Native SAP behavior: `CL_SALV_TREE` and its node, column, function,
  selection, item, and event helper classes provide high-level read-only tree
  output with link-click and double-click events.
- open-abap behavior: `CL_SALV_TREE`, `CL_SALV_NODES`, `CL_SALV_NODE`,
  `CL_SALV_ITEM`, `CL_SALV_COLUMNS_TREE`, `CL_SALV_COLUMN_TREE`,
  `CL_SALV_SELECTIONS_TREE`, `CL_SALV_FUNCTIONS_TREE`, and
  `CL_SALV_EVENTS_TREE` are now declared, along with `SALV_DE_NODE_KEY` and
  `SALV_T_NODES`. Every method body returns without behavior, so `FACTORY`
  yields an unbound tree, `ADD_NODE` returns no node reference, and
  `GET_SELECTED_NODES` returns an empty table. Only the confirmed part of the
  surface is declared: `CL_SALV_COLUMN_TREE` extends `CL_SALV_COLUMN` directly,
  so list-column extras such as `SET_KEY` are not available on a tree column;
  `CL_SALV_SELECTIONS_TREE` exposes no selection-mode setter;
  `CL_SALV_COLUMNS_TREE` offers only the exception-column accessors and no
  hierarchy-column getter; and `CL_SALV_TREE` has `DISPLAY` but no `REFRESH`.
- Reproduction: Call `CL_SALV_TREE=>FACTORY` with any internal table and inspect
  `R_SALV_TREE`; it remains initial because the body returns immediately.
- Workaround: `ZGG_GUI_SALV_TREE` declares the whole family statically, guards
  the factory, and displays a text fallback when the tree is unbound. Runtime
  node changes redraw with `DISPLAY` because no refresh entry point exists, and
  the sample no longer marks a key column or renames the hierarchy column.
  Static
  include `ZGG_NATIVE_SALV_TREE` declares typed native `LINK_CLICK` and
  `DOUBLE_CLICK` handlers, returns node and column payloads through ABAP memory,
  and deregisters on exit. That include now has no unresolved type references;
  lint issue reporting stays disabled for it only because of repository style
  rules such as the ban on `EXPORT TO MEMORY`.
- Upstream reference: Not reported

### Hierarchical-sequential SALV family is declared but has no runtime behavior

- Status: Open, confirmed
- Sample: `ZGG_GUI_SALV_HIERSEQ`
- Component: `open-abap-gui`
- Version or commit: `08bd747` (`open-abap-gui` local checkout, 2026-08-23);
  originally recorded against `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
- Native SAP behavior: `CL_SALV_HIERSEQ_TABLE` binds separate level-one and
  level-two tables through master/slave fields, then supplies per-level columns,
  sorting, filtering, aggregation, functions, refresh, and interaction events.
- open-abap behavior: `CL_SALV_HIERSEQ_TABLE`, `CL_SALV_COLUMNS_HIERSEQ`,
  `CL_SALV_COLUMN_HIERSEQ`, and `CL_SALV_EVENTS_HIERSEQ` are now declared, as
  are the `SALV_S_HIERSEQ_BINDING` structure and `SALV_T_HIERSEQ_BINDING` table
  type. Per-level sorting, filtering, and aggregation reuse the existing
  `CL_SALV_SORTS`, `CL_SALV_FILTERS`, and `CL_SALV_AGGREGATIONS` classes. Every
  method body returns without behavior, so `FACTORY` yields an unbound object
  and the per-level getters return unbound helpers.
- Reproduction: Call `CL_SALV_HIERSEQ_TABLE=>FACTORY` with two internal tables
  and a binding table, then inspect `R_HIERSEQ`; it remains initial because the
  body returns immediately.
- Workaround: `ZGG_GUI_SALV_HIERSEQ` declares the family statically, builds the
  binding through the native `SALV_T_HIERSEQ_BINDING` type and the
  `T_BINDING_LEVEL1_LEVEL2` contract, and shows a text fallback when the factory
  returns nothing. Static include `ZGG_NATIVE_SALV_HSEQ` declares typed
  `LINK_CLICK` and `DOUBLE_CLICK` handlers, records level, row, and column
  payloads, and deregisters on exit. That include now has no unresolved type
  references; lint issue reporting stays disabled for it only because of
  repository style rules such as the ban on `EXPORT TO MEMORY`.
- Upstream reference: Not reported

### Frontend Services is partial, stubbed, and has signature differences

- Status: Open, confirmed
- Sample: `ZGG_GUI_FRONTEND_SERVICES`
- Component: `open-abap-gui`
- Version or commit: `fbf93db` (`open-abap-gui` local checkout, 2026-08-23);
  originally recorded against `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
- Native SAP behavior: `CL_GUI_FRONTEND_SERVICES` provides security-mediated
  dialogs, text/binary transfer, file and directory operations, clipboard,
  frontend capability and path queries, read-only registry access, and opening
  a local file or URL. Calls can report missing GUI, background, unsupported
  frontend, and security rejection conditions.
- open-abap behavior: Dialog, upload/download, execute, clipboard, file
  existence/deletion, directory creation/listing/existence, path separator,
  SAP GUI work directory, and system-directory methods fail assertions. Many
  other methods return empty results. `GET_PLATFORM` always reports Windows XP
  and `GET_GUI_VERSION` returns dummy `9999/1/20` values. `GET_SAPGUI_DIRECTORY`
  and `DIRECTORY_SET_CURRENT` are now declared but return without querying the
  frontend, so the directory getters yield empty strings and the set call
  reports no return code. `CLIPBOARD_EXPORT` declares `DATA` as an `EXPORTING`
  parameter typed `any`, matching a long-standing quirk of the native class, so
  callers must pass the outgoing table with `IMPORTING`. There is no
  availability predicate and no GUI-type getter on the class; the sample's
  earlier `GUI_IS_AVAILABLE` and `GET_GUI_TYPE` calls named methods that the
  native class does not define.
- Reproduction: Call `FILE_EXIST` with any path; execution reaches
  `ASSERT 1 = 'file_exist not supported'` in
  `src/cl_gui_frontend_services.clas.abap`. Call `GET_SAPGUI_DIRECTORY` and
  inspect the changed parameter; it stays initial.
- Workaround: The sample calls every method statically, guards all calls,
  performs destructive actions only under a derived `ZGG_GUI_<user>` temporary
  directory, and treats capability outputs from open-abap as non-authoritative.
  Frontend availability is probed with `SY-BATCH` plus the `GET_GUI_VERSION`
  return code instead of a non-existent predicate.
- Upstream reference: Not reported

### Interactive drag/resize control is a runtime stub

- Status: Open, confirmed
- Sample: `ZGG_GUI_ILI_DRAGDROP`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_GUI_ILIDRAGNDROP_CONTROL` displays a movable and
  resizable interactive region, raises dropped/resized/context-menu events, and
  owns a configurable internal context menu.
- open-abap behavior: The class, constants, methods, and events are declared,
  but construction fails `ASSERT 1 = 'todo'`. Dragging, visibility, and every
  context-menu method return without frontend state or events.
- Reproduction: Construct the class with a valid GUI container; execution
  reaches the failed assertion in
  `src/cl_gui_ilidragndrop_control.clas.abap`.
- Workaround: The sample catches construction failure and shows a text
  fallback. Its native mode, geometry, visibility, event, and internal-menu
  calls remain syntax checked.
- Upstream reference: Not reported

### Generic drag-and-drop behavior has no runtime state

- Status: Open, confirmed
- Sample: `ZGG_GUI_DRAG_DROP`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_DRAGDROP` registers flavors, effects, sources, and
  targets and returns a behavior handle consumed by tree and ALV controls.
  `CL_DRAGDROPOBJECT` carries application data, effect, and lifecycle state and
  can abort a drop. The controls raise drag, flavor, drop, and completion events.
- open-abap behavior: `CL_DRAGDROP->ADD`, `GET`, and `GET_HANDLE` return without
  storing behavior or assigning a handle. `CL_DRAGDROPOBJECT->ABORT` does not
  change state. The column tree and ALV Grid constructors or display methods
  also terminate in assertions, so no frontend drag/drop sequence is raised.
- Reproduction: Create `CL_DRAGDROP`, call `ADD` followed by `GET_HANDLE`, and
  inspect the returned handle; it remains initial. Constructing either hosted
  target control reaches its existing runtime assertion.
- Workaround: The sample keeps the full native behavior, payload, event, and
  undo code syntax checked, catches control construction failure, and displays
  a diagnostic text fallback.
- Upstream reference: Not reported

### Optional graphics and selector classes have no runtime behavior

- Status: Open, confirmed
- Sample: `ZGG_GUI_GRAPHICS`
- Component: `open-abap-gui`
- Version or commit: `08bd747` (`open-abap-gui` local checkout, 2026-08-23);
  originally recorded against `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
- Native SAP behavior: Depending on release and frontend installation,
  `CL_GUI_BARCHART`, `CL_GUI_CHART_ENGINE`, `CL_GUI_GP_PRES`, and
  `CL_GUI_SELECTOR` host legacy bar charts, Chart Engine output, Graphical
  Framework business graphics, and a color selector. Chart Engine may fall
  back from the Windows ActiveX control to IGS.
- open-abap behavior: `CL_GUI_BARCHART`, `CL_GUI_CHART_ENGINE`,
  `CL_GUI_GP_PRES`, and `CL_GUI_SELECTOR` are now declared, together with the
  `IF_GRAPHIC_PROXY` interface used to activate the business-graphics proxy.
  Every method body returns without hosting a control. Only the release-stable
  part of each surface is declared: the bar chart offers `DISPLAY`, the Chart
  Engine `SET_DATA` and `RENDER`, and the selector nothing beyond its
  constructor. The data- and colour-transfer entry points of the bar chart and
  selector, and any constructor parameters for `CL_GUI_GP_PRES`, are release
  dependent and therefore not part of the checked surface. The wider Graphical
  Framework multiplexer and data-container family is still absent, so a native
  application cannot connect a data container before activating the proxy.
- Reproduction: Construct `CL_GUI_CHART_ENGINE` with a container and call
  `RENDER`; nothing is drawn because the body returns immediately. A static
  reference to a Graphical Framework data-container class still fails type
  resolution.
- Workaround: The sample audits each class with RTTI, declares each control
  statically behind its capability flag, and keeps a diagnostic text control
  visible when a class or frontend capability is unavailable.
- Upstream reference: Not reported

### Graphics dependency declarations deviate from the native SAP surface

- Status: Open, confirmed
- Sample: `ZGG_GUI_GRAPHICS`
- Component: `open-abap-gui` dependency surface
- Version or commit: `dc251c0` (`open-abap-gui` local checkout, 2026-08-23)
- Native SAP behavior: `CL_GUI_CHART_ENGINE` is a standalone class that drives
  either the frontend ActiveX engine or the IGS renderer; it does not inherit
  from `CL_GUI_CONTROL` and therefore has no control lifetime methods.
  `CL_GUI_GP_PRES->SET_DC_NAMES` requires the dimension parameters, so `DIM2`
  cannot be omitted.
- open-abap behavior: `CL_GUI_CHART_ENGINE` is declared as
  `INHERITING FROM cl_gui_control`, and every `SET_DC_NAMES` parameter is
  declared `OPTIONAL`. Both deviations are accepted by the lint run while a
  native syntax check rejects the same source, so the dependency surface is
  more permissive than the system it models.
- Reproduction: Assign a `CL_GUI_CHART_ENGINE` reference to a
  `CL_GUI_CONTROL` variable, or call `SET_DC_NAMES` without `DIM2`. The lint
  run reports no issue; the native syntax check reports a type conversion
  error and a missing mandatory parameter.
- Workaround: The sample keeps the chart engine in its own reference instead of
  the shared control variable, releases it by dropping that reference, and
  passes the dimension parameters explicitly.
- Upstream reference: Not reported

### Picture event surface and Data Provider lifetime constant are missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_PICTURE`
- Component: `open-abap-gui` dependency surface
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_GUI_PICTURE` exposes picture click/double-click
  events, and the CNDP type pool supplies `CNDP_LIFETIME_TRANSACTION` for
  `DP_CREATE_URL` data kept for the current transaction.
- open-abap behavior: `CL_GUI_PICTURE` declares no events, and the configured
  dependencies do not resolve `CNDP_LIFETIME_TRANSACTION`. A static event
  handler or use of the named lifetime constant therefore fails syntax/type
  checking.
- Reproduction: Declare a handler `FOR EVENT PICTURE_DBLCLICK OF
  CL_GUI_PICTURE`, or pass `CNDP_LIFETIME_TRANSACTION` to `DP_CREATE_URL`, and
  run `npm test`.
- Workaround: The format fixtures use the documented transaction lifetime
  value `'T'`. Static include `ZGG_NATIVE_PICTURE` declares the real
  click/double-click handlers, registers both event IDs, returns coordinates
  through ABAP memory, and deregisters during cleanup. Lint issue reporting is
  disabled only for this native include because open-abap lacks the event;
  activation and event behavior remain native-SAP checks.
- Upstream reference: Not reported

### The SLIS type pool and the REUSE_ALV_* family are missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_ALV_CLASSIC`
- Component: `open-abap-core` and `open-abap-gui` dependency surface
- Version or commit: `5623d54` (`open-abap-core`) and `a3453bd`
  (`open-abap-gui`), both resolved on 2026-08-23
- Native SAP behavior: The type pool `SLIS` supplies the field catalog, layout,
  sort, event, key-info, and list-header types, and function group `SLVC`
  supplies `REUSE_ALV_GRID_DISPLAY`, `REUSE_ALV_LIST_DISPLAY`,
  `REUSE_ALV_HIERSEQ_LIST_DISPLAY`, the block-list function modules,
  `REUSE_ALV_POPUP_TO_SELECT`, `REUSE_ALV_FIELDCATALOG_MERGE`,
  `REUSE_ALV_EVENTS_GET`, `REUSE_ALV_COMMENTARY_WRITE`, and
  `REUSE_ALV_VARIANT_F4`. The display function modules call back into form
  routines of the calling program for status, user command, and page headers.
- open-abap behavior: None of the `SLIS_*` types resolve, so every declaration
  that uses them is reported by `unknown_types`. Unknown function modules are
  not reported at all, so a call without typed parameters passes the lint run
  without any runtime behavior behind it.
- Reproduction: Declare `DATA lt TYPE slis_t_fieldcat_alv.` in any report under
  `src/` and run `npm test`; abaplint reports `SLIS_T_FIELDCAT_ALV not found`.
- Workaround: All SLIS-typed declarations, the `REUSE_ALV_*` calls, and the
  callback form routines are isolated in the static include
  `ZGG_NATIVE_ALV_CLASSIC`. Lint issue reporting is disabled only for that
  include; activation, the five display flavors, and the callbacks remain
  native-SAP checks.
- Upstream reference: Not reported

### Selection-variant types and RS_VARIANT_* function modules are missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_SEL_VARIANTS`
- Component: `open-abap-core` dependency surface
- Version or commit: `5623d54` (`open-abap-core`), resolved on 2026-08-23
- Native SAP behavior: `RSPARAMS`, `VARID`, `VARIT`, and `RSVAR` describe the
  contents and the directory entry of a selection variant.
  `RS_REFRESH_FROM_SELECTOPTIONS` reads the current selection screen,
  `RS_VARIANT_CATALOG` offers the variant value help, `RS_VARIANT_CONTENTS`
  reads a stored variant, and `RS_CREATE_VARIANT`,
  `RS_CHANGE_CREATED_VARIANT`, and `RS_VARIANT_DELETE` maintain it.
- open-abap behavior: None of the four structures resolve, so the sample cannot
  declare the variant contents, the variant description, or the F4 result.
  Variant persistence itself has no open-abap equivalent.
- Reproduction: Declare `DATA lt TYPE STANDARD TABLE OF rsparams.` in a report
  under `src/` and run `npm test`; abaplint reports `RSPARAMS not found`.
- Workaround: All variant-typed declarations, the `RS_*` calls, and the
  `SUBMIT` statements that pass a selection table or a selection set are
  isolated in the static include `ZGG_NATIVE_SEL_VARIANTS`. Only sample-owned
  `GG_` variants are written, and only after an explicit confirmation.
- Upstream reference: Not reported

### Dynamic-selection types and FREE_SELECTIONS_* function modules are missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_SEL_FREE`
- Component: `open-abap-core` dependency surface
- Version or commit: `5623d54` (`open-abap-core`), resolved on 2026-08-23
- Native SAP behavior: `RSDSTABS`, `RSDSFIELDS`, `RSDS_TEXPR`, `RSDS_TRANGE`,
  `RSDS_TWHERE`, and `RSDYNSEL-SELID` describe the tables, fields,
  expressions, ranges, WHERE clauses, and the selection id of a dynamic
  selection. `FREE_SELECTIONS_INIT` prepares it, `FREE_SELECTIONS_DIALOG`
  displays it as a window or full screen, and `FREE_SELECTIONS_RANGE_2_WHERE`
  converts the returned ranges into a WHERE clause.
- open-abap behavior: None of the `RSDS*` types or `RSDYNSEL` resolve, so the
  selection id, the field list, and every returned structure are unknown types.
  The dialog has no open-abap runtime.
- Reproduction: Declare `DATA lt TYPE STANDARD TABLE OF rsdsfields.` in a
  report under `src/` and run `npm test`; abaplint reports
  `RSDSFIELDS not found`.
- Workaround: The dynamic-selection state and all `FREE_SELECTIONS_*` calls are
  isolated in the static include `ZGG_NATIVE_SEL_FREE`. The sample displays the
  returned ranges and WHERE clauses and reads no data, so no database access is
  added to the repository.
- Upstream reference: Not reported
