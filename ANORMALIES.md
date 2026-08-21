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

### Native container classes are missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_DOCKING_CONTAINER`, `ZGG_GUI_SPLITTER_CONTAINER`, and
  `ZGG_GUI_DIALOG_CONTAINER`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_GUI_DOCKING_CONTAINER` docks a child control on any
  screen edge and can float it; `CL_GUI_EASY_SPLITTER_CONTAINER` divides a
  parent into two cells; and `CL_GUI_DIALOGBOX_CONTAINER` creates a modeless
  dialog with close and resize events.
- open-abap behavior: No class definitions for
  `CL_GUI_DOCKING_CONTAINER`, `CL_GUI_EASY_SPLITTER_CONTAINER`, or
  `CL_GUI_DIALOGBOX_CONTAINER` exist under `src` at the commit above. Static
  references therefore fail abaplint type resolution and the classes cannot be
  instantiated by the runtime.
- Reproduction: Add `DATA go_docking TYPE REF TO cl_gui_docking_container.` to
  a checked report and run `npm test`; abaplint reports the type as unknown.
  Fetching the corresponding `src/cl_gui_*_container.clas.abap` paths at the
  tested commit returns `404`.
- Workaround: The affected reports create optional native classes by runtime
  class name, catch creation failures, and operate through
  `CL_GUI_CONTAINER` where possible. This retains native SAP behavior and keeps
  the catalog syntax-checkable without declaring replacement global classes.
- Upstream reference: Not reported

### `CL_GUI_CALENDAR` is missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_CALENDAR`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_GUI_CALENDAR` displays localized calendar views,
  selects single dates or ranges, supplies date-selection and information
  events, and attaches colors and tooltip text to dates.
- open-abap behavior: The repository has no `CL_GUI_CALENDAR` class definition
  or associated `CNCA` calendar type surface, so static calendar code cannot be
  linted and the runtime cannot instantiate the control.
- Reproduction: Add `DATA go_calendar TYPE REF TO cl_gui_calendar.` to a checked
  report and run `npm test`; abaplint reports the type as unknown. No calendar
  class or `CNCA` artifact is present in the tested repository tree.
- Workaround: `ZGG_GUI_CALENDAR` creates the native class by runtime name,
  catches unavailable-control failures, and calls release-dependent methods
  dynamically. Static include `ZGG_NATIVE_CALENDAR` declares handlers for
  `DATE_SELECTED` and `INFO_REQUEST`, registers the native event IDs, returns
  event ranges through ABAP memory, and deregisters before recreation or exit.
  Local structurally compatible date-info types keep the owner report
  importable without declaring replacement SAP globals. Because open-abap lacks
  the calendar type surface, lint issue reporting is disabled only for this
  native include; activation and event behavior remain native-SAP checks.
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
- open-abap behavior: `src/dd` declares `CL_DD_DOCUMENT`, area, table, form,
  button, and input classes plus core `SDYDO` types, but their methods return
  without constructing HTML or element objects. The link and select element
  classes, `ADD_LINK`, `ADD_SELECT_ELEMENT`, and native element events are
  absent. A call to `VERTICAL_SPLIT`, for example, leaves `RIGHT_AREA` unbound.
- Reproduction: Create `CL_DD_DOCUMENT`, call `VERTICAL_SPLIT`, and inspect the
  exported `RIGHT_AREA`; it remains initial because the implementation returns
  immediately. Alternatively, add a static `document->add_link( )` call and run
  `npm test`; abaplint reports the missing method. The no-op implementations are
  under `src/dd` at the tested commit.
- Workaround: `ZGG_GUI_DYNAMIC_DOCUMENT` creates `CL_DD_DOCUMENT` by runtime
  class name, calls the native API dynamically, and uses local structurally
  compatible option types. If the class is unavailable or returns no child
  areas, it displays a clear HTML fallback through `CL_GUI_HTML_VIEWER`. Static
  include `ZGG_NATIVE_DOCUMENT` declares typed handlers for link/button
  `CLICKED`, input `ENTERED`/`HELP_F1`, and select `SELECTED`. It returns the
  sender name and current value through ABAP memory and deregisters before reset
  or exit. Because open-abap lacks the element classes and events, lint issue
  reporting is disabled only for this native include; activation and event
  behavior remain native-SAP checks.
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
  most inherited state methods return without behavior. `CL_GUI_SIMPLE_TREE`,
  `CL_GUI_LIST_TREE`, and the simple, list, and column tree-model classes are
  absent from the tested tree. Several native column-tree methods, including
  individual item mutation and node movement, are also missing from the type
  surface. The ALV tree constructor and core display/node/state methods are
  assertion stubs or no-ops, and its native context-menu request event is not
  declared even though context-menu selection is present.
- Reproduction: Create `CL_GUI_COLUMN_TREE` with a valid parent and hierarchy
  header; the constructor reaches `ASSERT 1 = 'todo'` in
  `src/cl_gui_column_tree.clas.abap`. A static reference to
  `CL_SIMPLE_TREE_MODEL` fails abaplint type resolution.
- Workaround: `ZGG_GUI_TREES` catches construction failures and shows a text
  fallback. It uses the statically available tree surface where possible and
  invokes missing but native node-movement APIs dynamically. The class-audit
  action reports which GUI and model variants exist on the current system.
  Static include `ZGG_NATIVE_ALV_TREE` declares a typed handler for the missing
  native `NODE_CONTEXT_MENU_REQUEST`, preserves the tree's existing frontend
  event registrations, adds two menu commands, and deregisters the handler on
  exit. Lint issue reporting is disabled only for this native include;
  activation and event behavior remain native-SAP checks.
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
  toggles, return without retaining state. Concrete SALV form-layout classes
  are absent from the tested source tree.
- Reproduction: Call `CL_SALV_TABLE=>FACTORY` with any internal table; the
  implementation reaches `ASSERT 1 = 'todo'` in
  `src/salv/cl_salv_table.clas.abap`. The other placeholder implementations are
  in `src/salv` at the commit above.
- Workaround: `ZGG_GUI_SALV_TABLE` catches construction failures and displays a
  read-only text fallback. Native form objects are instantiated by runtime
  class name so the report remains lintable against the partial open-abap type
  surface. There is no workaround for executing an interactive SALV table in
  the current runtime.
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
  DDIC artifacts are also absent from the tested repository tree.
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
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_ALV_VARIANT` binds an output table, LVC field
  catalog, layout, and `DISVARIANT` key; it reads stored field catalogs and can
  delete a supplied set of layout variants. The owning grid applies, saves, and
  switches variants for the same report and handle.
- open-abap behavior: `CL_ALV_VARIANT` is declared under `src/alv`, but its
  constructor, `GET_VARIANT_INFO_FROM_DB`, and `DELETE_VARIANTS` all return
  without retaining state, reading storage, or deleting anything. The related
  `CL_GUI_ALV_GRID` variant methods are also no-ops.
- Reproduction: Construct `CL_ALV_VARIANT`, call
  `GET_VARIANT_INFO_FROM_DB`, and inspect `ET_FCAT`; it remains initial because
  the implementation immediately returns in
  `src/alv/cl_alv_variant.clas.abap`.
- Workaround: The sample remains native-SAP-only for persistence. It tracks
  only successfully saved `GG_` keys for its own report and `GGV1` handle,
  requires explicit confirmation, and supplies only those tracked keys to
  dynamic `DELETE_VARIANTS` calls.
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
  `LVC_S_STYL` and `LVC_T_STYL` DDIC artifacts are absent.
- Reproduction: Construct `CL_ALV_CHANGED_DATA_PROTOCOL` and call
  `ADD_PROTOCOL_ENTRY`; execution reaches `ASSERT 1 = 'todo'` in
  `src/alv/cl_alv_changed_data_protocol.clas.abap`.
- Workaround: The report is native-SAP-only for editing and validation. It uses
  a local structurally compatible style component for the output row and
  catches grid construction failure before any interactive edit path runs.
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

### SALV tree class family is missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_SALV_TREE`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_SALV_TREE` and its node, column, function,
  selection, item, and event helper classes provide high-level read-only tree
  output with link-click and double-click events.
- open-abap behavior: No `CL_SALV_TREE`, node collection/node, tree column,
  tree selection, function, item, or tree event class definitions exist in the
  tested repository tree. Static references fail type resolution and no SALV
  tree can be created at runtime.
- Reproduction: Add `DATA tree TYPE REF TO cl_salv_tree.` to a checked report
  and run `npm test`; abaplint reports the unknown type. Repository searches for
  the SALV tree class family at the tested commit return no files.
- Workaround: `ZGG_GUI_SALV_TREE` invokes the native factory and helper methods
  dynamically and displays a text fallback when unavailable. Static include
  `ZGG_NATIVE_SALV_TREE` declares typed native `LINK_CLICK` and `DOUBLE_CLICK`
  handlers, returns node and column payloads through ABAP memory, and
  deregisters on exit. Lint issue reporting is disabled only for this native
  include; activation and event behavior remain native-SAP checks.
- Upstream reference: Not reported

### Hierarchical-sequential SALV class family is missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_SALV_HIERSEQ`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_SALV_HIERSEQ_TABLE` binds separate level-one and
  level-two tables through master/slave fields, then supplies per-level columns,
  sorting, filtering, aggregation, functions, refresh, and interaction events.
- open-abap behavior: The hierarchical-sequential SALV table, its level helper
  classes, binding type, and its event class are absent from the tested
  repository tree. Static references fail type resolution and the runtime
  cannot create this SALV variant.
- Reproduction: Add `DATA output TYPE REF TO cl_salv_hierseq_table.` to a
  checked report and run `npm test`; abaplint reports the unknown type.
  Repository searches at the tested commit return no hierarchical-sequential
  SALV classes.
- Workaround: `ZGG_GUI_SALV_HIERSEQ` uses a local structurally compatible
  master/slave binding table and invokes the native factory and level methods
  dynamically with the native `T_BINDING_LEVEL1_LEVEL2` contract. Static include
  `ZGG_NATIVE_SALV_HSEQ` declares typed `LINK_CLICK` and `DOUBLE_CLICK` handlers,
  records level, row, and column payloads, and deregisters on exit. Lint issue
  reporting is disabled only for this native include; activation and event
  behavior remain native-SAP checks.
- Upstream reference: Not reported

### Frontend Services is partial, stubbed, and has signature differences

- Status: Open, confirmed
- Sample: `ZGG_GUI_FRONTEND_SERVICES`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_GUI_FRONTEND_SERVICES` provides security-mediated
  dialogs, text/binary transfer, file and directory operations, clipboard,
  frontend capability and path queries, read-only registry access, and opening
  a local file or URL. Calls can report missing GUI, background, unsupported
  frontend, and security rejection conditions.
- open-abap behavior: Dialog, upload/download, execute, clipboard, file
  existence/deletion, directory creation/listing/existence, path separator,
  SAP GUI work directory, and system-directory methods fail assertions. Many
  other methods return empty results. `GET_PLATFORM` always reports Windows XP
  and `GET_GUI_VERSION` returns dummy `9999/1/20` values. Native methods such as
  `GUI_IS_AVAILABLE`, `GET_GUI_TYPE`, `GET_SAPGUI_DIRECTORY`, and
  `DIRECTORY_SET_CURRENT` are absent; clipboard parameter directions also
  differ from native SAP.
- Reproduction: Call `FILE_EXIST` with any path; execution reaches
  `ASSERT 1 = 'file_exist not supported'` in
  `src/cl_gui_frontend_services.clas.abap`. A static call to
  `GUI_IS_AVAILABLE` fails abaplint method lookup at the tested commit.
- Workaround: The sample dynamically invokes absent or signature-incompatible
  native methods, guards all calls, performs destructive actions only under a
  derived `ZGG_GUI_<user>` temporary directory, and treats capability outputs
  from open-abap as non-authoritative.
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

### Desktop Office Integration class family is missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_OFFICE_INTEGRATION`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `C_OI_CONTAINER_CONTROL_CREATOR` supplies a central
  Desktop Office container. Its document proxies embed registered desktop
  applications and expose spreadsheet and word-processing interfaces with
  explicit document and automation-object cleanup.
- open-abap behavior: The creator, container and document proxy interfaces,
  spreadsheet and word-processing interfaces, Office error class, and SOI type
  pool are absent from the tested repository tree. Static declarations cannot
  be resolved and no Office application can be hosted.
- Reproduction: Add `DATA control TYPE REF TO i_oi_container_control.` or a
  static call to `C_OI_CONTAINER_CONTROL_CREATOR=>GET_CONTAINER_CONTROL` and
  run `npm test`; abaplint reports unknown types/classes.
- Workaround: The sample checks the creator class with RTTI, performs native
  factory and interface calls dynamically, and shows a diagnostic text control
  when unavailable. It never assumes that Windows or Microsoft Office is
  installed.
- Upstream reference: Not reported

### Optional graphics and selector classes are missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_GRAPHICS`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: Depending on release and frontend installation,
  `CL_GUI_BARCHART`, `CL_GUI_CHART_ENGINE`, `CL_GUI_GP_PRES`, and
  `CL_GUI_SELECTOR` host legacy bar charts, Chart Engine output, Graphical
  Framework business graphics, and a color selector. Chart Engine may fall
  back from the Windows ActiveX control to IGS.
- open-abap behavior: None of these four classes, the Graphical Framework
  multiplexer/data-container family, or their required types are present in the
  tested repository tree. Static declarations fail type resolution and no
  optional graphic can be hosted.
- Reproduction: Add `DATA chart TYPE REF TO cl_gui_chart_engine.` to a checked
  report and run `npm test`; abaplint reports the unknown type. The same occurs
  for the bar chart, business-graphics proxy, and selector classes.
- Workaround: The sample audits each class with RTTI, creates only installed
  variants through dynamic calls, and keeps a diagnostic text control visible
  when a class or frontend capability is unavailable.
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
