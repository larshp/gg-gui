# Transpiler and Runtime Anomalies

Record differences between native SAP behavior and the open-abap transpiler or
runtime here. Also record SAP APIs needed by a sample that are missing or only
partially declared in open-abap.

Do not record ordinary sample defects, SAP release differences, unsupported SAP
GUI frontend features, or local development-environment failures in this file.
Stubbed implementations are expected: an open-abap method that is declared but
returns without behavior, fails an `ASSERT`, or yields a placeholder result is
not an anomaly and is not recorded. Record only surface that is absent,
incompletely declared, or declared differently from native SAP.

## Entry Template

### Short title

- Status: Open, confirmed, reported, fixed, or accepted limitation
- Sample: `ZGG_GUI_*`
- Component: Transpiler, runtime, `open-abap-core`, or `open-abap-gui`
- Version or commit: Exact tested version or commit
- Native SAP behavior: What the declared SAP baseline offers
- open-abap behavior: How the open-abap surface differs from it
- Reproduction: Minimal commands and source needed to reproduce it
- Workaround: Current workaround, or `None`
- Upstream reference: Issue or pull request URL, or `Not reported`

## Recorded Anomalies

### `CL_CTMENU` has a partial API

- Status: Open, confirmed
- Sample: `ZGG_GUI_GUI_STATUS`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_CTMENU` can add functions, separators, and submenus;
  enable, disable, show, or hide functions; load a Menu Painter status; and mark
  a default function.
- open-abap behavior: `ADD_FUNCTION`, `ADD_SEPARATOR`, `ADD_SUBMENU`, `CLEAR`,
  and `HIDE_FUNCTIONS` are declared. `SET_DEFAULT_FUNCTION`, `LOAD_GUI_STATUS`,
  `DISABLE_FUNCTIONS`, `ENABLE_FUNCTIONS`, and the other public native methods
  are absent from the class definition, so any call to them fails type
  resolution.
- Reproduction: Add
  `io_menu->set_default_function( fcode = 'APPLY' ).` where `io_menu` is typed
  as `REF TO cl_ctmenu`, then run `npm test`. abaplint reports method
  `SET_DEFAULT_FUNCTION` as missing.
- Workaround: Omit the default-function marker so the native SAP sample remains
  type-compatible with the available open-abap surface.
- Upstream reference: Not reported

### `CL_GUI_CONTROL` lifetime constants are missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_CFW_BASICS` and `ZGG_GUI_CUSTOM_CONTAINER`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_GUI_CONTROL` publishes `LIFETIME_DEFAULT`,
  `LIFETIME_DYNPRO`, and `LIFETIME_IMODE` with the values `0`, `1`, and `2`,
  and container constructors take them for their `LIFETIME` parameter.
- open-abap behavior: The class declares the alignment and window-style
  constants but none of the three lifetime constants, so a reference to any of
  them fails type resolution even though the `LIFETIME` parameters themselves
  are declared.
- Reproduction: Reference `cl_gui_control=>lifetime_dynpro` in a checked report
  and run `npm test`; abaplint reports the constant as not found.
- Workaround: `ZGG_GUI_CUSTOM_CONTAINER` declares the three lifetime modes as
  local constants `C_LIFETIME_DEFAULT`, `C_LIFETIME_DYNPRO`, and
  `C_LIFETIME_IMODE` with their native values `0`, `1`, and `2`.
- Upstream reference: Not reported

### `CL_GUI_SIMPLE_TREE` and `CL_GUI_LIST_TREE` are absent

- Status: Open, confirmed
- Sample: `ZGG_GUI_TREES` and `ZGG_GUI_TREE_MODELS`
- Component: `open-abap-gui`
- Version or commit: `1949361` (`open-abap-gui` local checkout, 2026-08-23);
  originally recorded against `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
- Native SAP behavior: SAP provides three GUI tree controls,
  `CL_GUI_SIMPLE_TREE`, `CL_GUI_LIST_TREE`, and `CL_GUI_COLUMN_TREE`, plus the
  corresponding backend tree-model classes.
- open-abap behavior: `CL_GUI_COLUMN_TREE` is declared together with
  `CL_TREE_CONTROL_BASE`, `CL_ITEM_TREE_CONTROL`, the ALV tree classes, and the
  backend models `CL_TREE_MODEL`, `CL_ITEM_TREE_MODEL`, `CL_SIMPLE_TREE_MODEL`,
  `CL_LIST_TREE_MODEL`, and `CL_COLUMN_TREE_MODEL`, along with the `MTREE*`
  node/item structures and the `TREEMSNOTA` / `TREEMLNOTA` / `TREEMCNOTA` /
  `TREEMLITAC` / `TREEMCITAC` table types. The simple and list GUI tree
  controls themselves are absent, so a static reference to either fails type
  resolution.
- Reproduction: Declare `DATA lo TYPE REF TO cl_gui_simple_tree.` in a checked
  report and run `npm test`; abaplint reports the class as not found.
- Workaround: `ZGG_GUI_TREES` uses the column tree only, and its class-audit
  action reports which GUI and model variants exist on the current system, so
  the two absent controls stay a native-SAP check.
- Upstream reference: Not reported

### ALV Grid standard function-code constants hold a placeholder value

- Status: Open, confirmed
- Sample: `ZGG_GUI_ALV_GRID` and `ZGG_GUI_ALV_FORMAT`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_GUI_ALV_GRID` publishes its standard toolbar function
  codes as the `MC_FC_*` constants, so an application can exclude or recognize a
  standard function by constant instead of by literal.
- open-abap behavior: Every `MC_FC_*` constant is declared with the placeholder
  value `TODO` instead of its native function code. The constants therefore
  resolve and the lint run reports nothing, but they all compare equal, so a
  toolbar-exclusion table built from two different constants silently holds the
  same value twice.
- Reproduction: Inspect the `MC_FC_*` constants in
  `src/cl_gui_alv_grid.clas.abap`; each one holds `TODO`. `ZGG_GUI_ALV_GRID`
  passes `MC_FC_GRAPH` and `MC_FC_WORD_PROCESSOR` to `IT_TOOLBAR_EXCLUDING`,
  and under open-abap both evaluate to the same placeholder.
- Workaround: None. The sample uses the native constants as an application
  should; the wrong values only matter once a runtime consumes them.
- Upstream reference: Not reported

### The ALV Grid `DELAYED_CHANGED_SEL_CALLBACK` event is missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_ALV_EVENTS`
- Component: `open-abap-gui`
- Version or commit: `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
  (repository `main` resolved on 2026-08-21)
- Native SAP behavior: `CL_GUI_ALV_GRID` raises
  `DELAYED_CHANGED_SEL_CALLBACK` after `REGISTER_DELAYED_EVENT` has been called
  with `MC_EVT_DELAYED_CHANGE_SELECT`, so an application can react to a
  settled selection instead of to every intermediate one.
- open-abap behavior: The grid declares most events but omits
  `DELAYED_CHANGED_SEL_CALLBACK` while retaining `REGISTER_DELAYED_EVENT` and
  its event ID, so the registration call resolves but the event it enables does
  not exist.
- Reproduction: Search `src/cl_gui_alv_grid.clas.abap` for the event;
  `MC_EVT_DELAYED_CHANGE_SELECT` and `REGISTER_DELAYED_EVENT` are present but no
  `DELAYED_CHANGED_SEL_CALLBACK` event is declared. A handler that imports no
  event parameters is not reported by abaplint, so the missing event stays
  silent in the lint run and only fails a native syntax check.
- Workaround: Static include `ZGG_NATIVE_ALV_EVENTS` declares a typed handler
  for the missing callback, registers `MC_EVT_DELAYED_CHANGE_SELECT`, preserves
  the handler across application/system event-mode recreation, and deregisters
  it before freeing the grid. The handler imports no parameters, so the include
  is lint checked without exclusions; existence of the event, activation, and
  event behavior remain native-SAP checks.
- Upstream reference: Not reported

### The SALV tree class API is partial

- Status: Open, confirmed
- Sample: `ZGG_GUI_SALV_TREE`
- Component: `open-abap-gui`
- Version or commit: `08bd747` (`open-abap-gui` local checkout, 2026-08-23);
  originally recorded against `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
- Native SAP behavior: `CL_SALV_TREE` and its node, column, function, selection,
  item, and event helper classes provide high-level read-only tree output. A
  tree column carries the list-column extras such as `SET_KEY`, selections
  expose a selection-mode setter, the columns collection exposes the hierarchy
  column, and the tree can be refreshed as well as displayed.
- open-abap behavior: `CL_SALV_TREE`, `CL_SALV_NODES`, `CL_SALV_NODE`,
  `CL_SALV_ITEM`, `CL_SALV_COLUMNS_TREE`, `CL_SALV_COLUMN_TREE`,
  `CL_SALV_SELECTIONS_TREE`, `CL_SALV_FUNCTIONS_TREE`, and
  `CL_SALV_EVENTS_TREE` are declared, along with `SALV_DE_NODE_KEY` and
  `SALV_T_NODES`, but only part of each surface is present:
  `CL_SALV_COLUMN_TREE` extends `CL_SALV_COLUMN` directly, so `SET_KEY` and the
  other list-column extras are unavailable on a tree column;
  `CL_SALV_SELECTIONS_TREE` exposes no selection-mode setter;
  `CL_SALV_COLUMNS_TREE` offers only the exception-column accessors and no
  hierarchy-column getter; and `CL_SALV_TREE` has `DISPLAY` but no `REFRESH`.
- Reproduction: Call `SET_KEY` on a `CL_SALV_COLUMN_TREE` reference, or
  `REFRESH` on a `CL_SALV_TREE` reference, and run `npm test`; abaplint reports
  the method as missing.
- Workaround: `ZGG_GUI_SALV_TREE` does not mark a key column or rename the
  hierarchy column, and redraws runtime node changes with `DISPLAY` because no
  refresh entry point exists.
- Upstream reference: Not reported

### The Graphical Framework data-container family is absent

- Status: Open, confirmed
- Sample: `ZGG_GUI_GRAPHICS`
- Component: `open-abap-gui`
- Version or commit: `08bd747` (`open-abap-gui` local checkout, 2026-08-23);
  originally recorded against `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
- Native SAP behavior: Depending on release and frontend installation,
  `CL_GUI_BARCHART`, `CL_GUI_CHART_ENGINE`, `CL_GUI_GP_PRES`, and
  `CL_GUI_SELECTOR` host legacy bar charts, Chart Engine output, Graphical
  Framework business graphics, and a color selector. A business-graphics
  application connects a Graphical Framework data container through the
  multiplexer before activating the proxy.
- open-abap behavior: `CL_GUI_BARCHART`, `CL_GUI_CHART_ENGINE`,
  `CL_GUI_GP_PRES`, and `CL_GUI_SELECTOR` are declared together with the
  `IF_GRAPHIC_PROXY` interface, but only the release-stable part of each
  surface: the bar chart offers `DISPLAY`, the Chart Engine `SET_DATA` and
  `RENDER`, and the selector nothing beyond its constructor. The data- and
  colour-transfer entry points of the bar chart and selector, and any
  constructor parameters for `CL_GUI_GP_PRES`, are release dependent and
  therefore not part of the checked surface. The wider Graphical Framework
  multiplexer and data-container family is absent, so a native application
  cannot connect a data container before activating the proxy.
- Reproduction: Declare a reference to a Graphical Framework data-container
  class and run `npm test`; abaplint reports the class as not found.
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

### The Data Provider lifetime constants are missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_PICTURE`
- Component: `open-abap-gui` dependency surface
- Version or commit: `1949361` (`open-abap-gui` local checkout, 2026-08-23);
  originally recorded against `7643d3b98058b1c47509e1a42af3187b7f6fbff7`
- Native SAP behavior: The CNDP type pool supplies `CNDP_LIFETIME_TRANSACTION`
  and its siblings for `DP_CREATE_URL` data kept for the current transaction.
- open-abap behavior: The CNDP type pool is absent from the dependency surface,
  so `CNDP_LIFETIME_TRANSACTION` does not resolve and the lifetime has to be
  passed as a literal. The picture control itself is complete for the sample:
  `CL_GUI_PICTURE` declares the native `PICTURE_CLICK` and `PICTURE_DBLCLICK`
  events with their `MOUSE_POS_X` / `MOUSE_POS_Y` parameters and the six
  `EVENTID_*` constants with their native values.
- Reproduction: Pass `CNDP_LIFETIME_TRANSACTION` to `DP_CREATE_URL` and run
  `npm test`; abaplint reports the constant as not found.
- Workaround: The format fixtures use the documented transaction lifetime
  value `'T'`. Static include `ZGG_NATIVE_PICTURE` declares the
  click/double-click handlers, registers both event IDs, returns coordinates
  through ABAP memory, and deregisters during cleanup. The include is lint
  checked without exclusions; activation and event behavior remain native-SAP
  checks.
- Upstream reference: Not reported

### The REUSE_ALV_* function modules are missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_ALV_CLASSIC`
- Component: `open-abap-gui` dependency surface
- Version or commit: `1949361` (`open-abap-gui` local checkout, 2026-08-23);
  originally recorded against `5623d54` (`open-abap-core`) and `a3453bd`
  (`open-abap-gui`)
- Native SAP behavior: The type pool `SLIS` supplies the field catalog, layout,
  sort, event, key-info, and list-header types, and function group `SLVC`
  supplies `REUSE_ALV_GRID_DISPLAY`, `REUSE_ALV_LIST_DISPLAY`,
  `REUSE_ALV_HIERSEQ_LIST_DISPLAY`, the block-list function modules,
  `REUSE_ALV_POPUP_TO_SELECT`, `REUSE_ALV_FIELDCATALOG_MERGE`,
  `REUSE_ALV_EVENTS_GET`, `REUSE_ALV_COMMENTARY_WRITE`, and
  `REUSE_ALV_VARIANT_F4`. The display function modules call back into form
  routines of the calling program for status, user command, and page headers.
- open-abap behavior: The `SLIS` type pool in
  `open-abap-gui/src/ddic/pools/slis.type.abap` supplies
  `SLIS_FIELDCAT_ALV` / `SLIS_T_FIELDCAT_ALV`, `SLIS_LAYOUT_ALV`,
  `SLIS_SORTINFO_ALV` / `SLIS_T_SORTINFO_ALV`, `SLIS_ALV_EVENT` /
  `SLIS_T_EVENT`, `SLIS_KEYINFO_ALV`, `SLIS_SELFIELD`, `SLIS_EXTAB` /
  `SLIS_T_EXTAB`, and the underlying `SLIS_FIELDNAME`, `SLIS_TABNAME`,
  `SLIS_FORMNAME`, `SLIS_EDIT_MASK`, and `SLIS_SEL_TAB_FIELD` types alongside
  the `SLIS_LISTHEADER` types, so every SLIS-typed declaration resolves.
  `SLIS_LAYOUT_ALV` reproduces the native component list except `DTC_LAYOUT`,
  which is omitted because its type `DTC_S_LAYO` is not part of the dependency
  surface. Function group `SLVC` itself is absent, and unknown function modules
  are not reported at all, so the `REUSE_ALV_*` calls pass the lint run with
  nothing behind them.
- Reproduction: Search the dependency surface for `REUSE_ALV_GRID_DISPLAY`; no
  function group provides it, yet `npm test` reports no issue for the call.
- Workaround: All SLIS-typed declarations, the `REUSE_ALV_*` calls, and the
  callback form routines are isolated in the static include
  `ZGG_NATIVE_ALV_CLASSIC`. The include is lint checked without exclusions.
  The `function_module_recommendations` rule is disabled in `abaplint.jsonc`
  because this sample exists to demonstrate the `REUSE_ALV_*` family itself, so
  its advice to replace `REUSE_ALV_GRID_DISPLAY` with `CL_SALV_TABLE=>FACTORY`
  or `CL_GUI_ALV_GRID` does not apply. Activation, the five display flavors,
  and the callbacks remain native-SAP checks.
- Upstream reference: Not reported

### The RS_VARIANT_* function modules and variant persistence are missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_SEL_VARIANTS`
- Component: `open-abap-gui` dependency surface
- Version or commit: `1949361` (`open-abap-gui` local checkout, 2026-08-23);
  originally recorded against `5623d54` (`open-abap-core`)
- Native SAP behavior: `RSPARAMS`, `VARID`, `VARIT`, and `RSVAR` describe the
  contents and the directory entry of a selection variant.
  `RS_REFRESH_FROM_SELECTOPTIONS` reads the current selection screen,
  `RS_VARIANT_CATALOG` offers the variant value help, `RS_VARIANT_CONTENTS`
  reads a stored variant, and `RS_CREATE_VARIANT`,
  `RS_CHANGE_CREATED_VARIANT`, and `RS_VARIANT_DELETE` maintain it.
- open-abap behavior: All four structures are declared under
  `open-abap-gui/src/ddic`: `RSPARAMS` and `RSVAR` as internal structures, and
  `VARID` and `VARIT` as transparent tables with their native key fields, so
  the variant contents, the variant description, and the F4 result all resolve.
  The `RS_*` function modules are absent, and variant persistence itself has no
  open-abap equivalent. Unknown function modules are not reported, so the calls
  pass the lint run with nothing behind them.
- Reproduction: Call `RS_VARIANT_CONTENTS` for any report and variant.
  `npm test` reports no issue, and nothing is read because the function module
  does not exist in the dependency surface.
- Workaround: All variant-typed declarations, the `RS_*` calls, and the
  `SUBMIT` statements that pass a selection table or a selection set are
  isolated in the static include `ZGG_NATIVE_SEL_VARIANTS`, which is lint
  checked without exclusions. Only sample-owned `GG_` variants are written, and
  only after an explicit confirmation.
- Upstream reference: Not reported

### The FREE_SELECTIONS_* function modules are missing

- Status: Open, confirmed
- Sample: `ZGG_GUI_SEL_FREE`
- Component: `open-abap-gui` dependency surface
- Version or commit: `1949361` (`open-abap-gui` local checkout, 2026-08-23);
  originally recorded against `5623d54` (`open-abap-core`)
- Native SAP behavior: `RSDSTABS`, `RSDSFIELDS`, `RSDS_TEXPR`, `RSDS_TRANGE`,
  `RSDS_TWHERE`, and `RSDYNSEL-SELID` describe the tables, fields,
  expressions, ranges, WHERE clauses, and the selection id of a dynamic
  selection. `FREE_SELECTIONS_INIT` prepares it, `FREE_SELECTIONS_DIALOG`
  displays it as a window or full screen, and `FREE_SELECTIONS_RANGE_2_WHERE`
  converts the returned ranges into a WHERE clause.
- open-abap behavior: The `RSDS` type group is declared in
  `open-abap-gui/src/ddic/pools/rsds.type.abap` with `RSDS_TRANGE` /
  `RSDS_RANGE` / `RSDS_FRANGE_T` / `RSDS_FRANGE` / `RSDS_SELOPT_T`,
  `RSDS_TWHERE` / `RSDS_WHERE` / `RSDS_WHERE_TAB`, `RSDS_TEXPR` / `RSDS_EXPR` /
  `RSDS_EXPR_TAB`, and the `RSDS_TYPE` structure used as a logical-database
  `DYN_SEL` parameter. The DDIC structures those types are built from,
  `RSDSTABS`, `RSDSFIELDS`, `RSDSSELOPT`, `RSDSWHERE`, `RSDSEXPR`, and
  `RSDYNSEL`, are declared under `open-abap-gui/src/ddic`, so the selection id,
  the field list, and every returned structure resolve. abaplint resolves the
  `RSDS_*` names through the type group by name prefix, so no `TYPE-POOLS`
  statement is needed in the sample. The `FREE_SELECTIONS_*` function modules
  are absent and the dialog has no open-abap equivalent; unknown function
  modules are not reported, so the calls pass the lint run with nothing behind
  them.
- Reproduction: Call `FREE_SELECTIONS_INIT` for table `T100`; `npm test`
  reports no issue, and no selection id is returned because the function module
  does not exist in the dependency surface.
- Workaround: The dynamic-selection state and all `FREE_SELECTIONS_*` calls are
  isolated in the static include `ZGG_NATIVE_SEL_FREE`, which is lint checked
  without exclusions. The sample displays the returned ranges and WHERE clauses
  and reads no data, so no database access is added to the repository.
- Upstream reference: Not reported
