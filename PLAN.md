# SAP GUI Sample Catalog

## Goal

Build a curated, runnable collection of ABAP programs that demonstrates the
standard SAP GUI screen elements, SAP Control Framework containers and
controls, common ALV variants, frontend integration APIs, and selected legacy
techniques.

The collection should favor small programs that teach one subject clearly.
Larger composition samples should only be used where interaction between
multiple controls is the point of the example.

## Scope

The catalog includes:

- Selection-screen elements created with ABAP statements.
- Classic dynpro elements created in Screen Painter.
- GUI statuses created in Menu Painter.
- Public SAP Control Framework containers and controls.
- SALV and ALV controls commonly used in SAP GUI applications.
- Standard dialogs and frontend services that form part of normal SAP GUI
  workflows.
- Legacy techniques that are still encountered in maintained ABAP systems.

The catalog does not attempt to include:

- SAPUI5, Fiori, Web Dynpro ABAP, Business Server Pages, or SAP Screen Personas.
- SAP GUI Scripting API objects, because these automate a GUI rather than build
  one from ABAP.
- Private, internal, or unreleased SAP classes.
- Controls installed by optional industry solutions or third-party add-ons.
- Every method of every control. Each sample covers representative display,
  input, event, refresh, and cleanup behavior instead.

Base classes, event payloads, exceptions, interfaces, DDIC structures, and type
pools do not receive standalone programs. Compatibility artifacts such as
`CL_GUI_ALV_GRID_BASE`, `CL_ALV_EVENT_DATA`, `CL_ALV_EVENT_TOOLBAR_SET`,
`CL_DD_ELEMENT`, SALV base and exception classes, and LVC structures are
covered through the runnable sample that consumes them.

Controls that depend on the frontend, operating system, installed desktop
software, or ABAP Platform release must be labeled as optional and must fail
gracefully when unavailable.

## Naming and Structure

- Use the `ZGG_GUI_*` prefix for executable sample programs.
- Prefer executable reports that can be started directly from SE38 or SA38.
- Use screen `0100` as the main screen where a custom dynpro is required.
- Use additional screens in predictable groups such as `0110`, `0120`, and
  `0200`.
- Keep screens, GUI statuses, titles, text symbols, and documentation with the
  report that owns them.
- Add transactions only where transaction-specific behavior is being taught.
- Use generated, deterministic demo data instead of productive or customizing
  tables.
- Put shared data generation and small presentation helpers in
  `ZCL_GG_GUI_DEMO_DATA` and `ZCL_GG_GUI_DEMO_HELPER`.
- Use local classes for event handlers that are meaningful only to one sample.

## Program Inventory

### 00. Catalog and Control Framework Fundamentals

#### `ZGG_GUI_CATALOG` - Sample launcher

- [ ] List every sample by category, title, and program name.
- [ ] Launch executable reports and return to the catalog afterward.

#### `ZGG_GUI_CFW_BASICS` - Control Framework lifecycle

- [ ] Create a control once during PBO and reuse it on later round trips.
- [ ] Register and handle system and application events.
- [ ] Demonstrate `CL_GUI_CFW=>DISPATCH` and `CL_GUI_CFW=>FLUSH`.
- [ ] Demonstrate `SET_NEW_OK_CODE`, `UPDATE_VIEW`, and metric-to-pixel
  conversion.
- [ ] Set focus and inspect the active control.
- [ ] Check validity and frontend technology flags through `CL_GUI_OBJECT`.
- [ ] Set visibility, enablement, alignment, position, width, and height through
  common `CL_GUI_CONTROL` methods.
- [ ] Refresh frontend state without recreating the control.
- [ ] Free controls in the correct child-to-parent order.
- [ ] Handle Control Framework and automation errors.
- [ ] Display an event log that makes PBO, PAI, and control events visible.

### 10. Selection Screens

#### `ZGG_GUI_SEL_FIELDS` - Parameter field variants

- [ ] Character, numeric, date, time, quantity, currency, and boolean fields.
- [ ] Checkbox and radio-button group parameters.
- [ ] Dropdown list box populated through `VRM_SET_VALUES`.
- [ ] Obligatory, lowercase, visible-length, memory-ID, and default values.
- [ ] DDIC-bound labels, conversion exits, search help, and parameter IDs.
- [ ] Password-style input where supported and appropriate.

#### `ZGG_GUI_SEL_RANGES` - Select-options and ranges

- [ ] Single values, intervals, patterns, inclusions, and exclusions.
- [ ] Multiple-selection dialog.
- [ ] `NO-EXTENSION`, `NO INTERVALS`, and `OBLIGATORY` variants.
- [ ] Default values and default ranges.
- [ ] Restriction with `SELECT_OPTIONS_RESTRICT`.
- [ ] Display the resulting range table after execution.

#### `ZGG_GUI_SEL_LAYOUT` - Selection-screen layout

- [ ] Framed and unframed blocks.
- [ ] Comments, horizontal lines, blank lines, and explicit positions.
- [ ] Multiple elements on one line.
- [ ] Selection-screen pushbuttons with user commands.
- [ ] Application-toolbar function keys through `SSCRFIELDS`.
- [ ] Icons and quick-info text where selection screens support them.

#### `ZGG_GUI_SEL_DYNAMIC` - Dynamic selection screens

- [ ] Group elements with `MODIF ID`.
- [ ] Change input, output, active, invisible, required, and intensified state.
- [ ] React to radio buttons, checkboxes, list boxes, and pushbuttons.
- [ ] Demonstrate `AT SELECTION-SCREEN OUTPUT`.
- [ ] Field, block, and radio-group validation events.
- [ ] Custom value-request and help-request handlers.
- [ ] Place the cursor on the field that failed validation.

#### `ZGG_GUI_SEL_TABS` - Selection-screen subscreens and tabs

- [ ] Define selection screens as subscreens.
- [ ] Create a tabbed block with at least three pages.
- [ ] Switch pages through user commands.
- [ ] Preserve field values while switching tabs.
- [ ] Validate active and inactive tab contents correctly.

### 20. Classic Dynpro Elements

#### `ZGG_GUI_DYNPRO_ELEMENTS` - Screen Painter element gallery

- [ ] Static text fields and input/output fields.
- [ ] Output-only, required, invisible, and intensified fields.
- [ ] Date, time, numeric, quantity, currency, and masked templates.
- [ ] Dropdown list boxes.
- [ ] Checkboxes and radio-button groups with and without function codes.
- [ ] Text and icon pushbuttons.
- [ ] Group boxes and framed areas.
- [ ] Status icons with text and quick info.
- [ ] Demonstrate field attributes inherited from DDIC references.

#### `ZGG_GUI_DYNPRO_FLOW` - PBO, PAI, and dynamic field behavior

- [ ] PBO and PAI module sequence.
- [ ] `FIELD`, `CHAIN`, and `ENDCHAIN` validation.
- [ ] `ON INPUT`, `ON REQUEST`, and chain-level validation.
- [ ] `LOOP AT SCREEN` and `MODIFY SCREEN`.
- [ ] Set and read the cursor position.
- [ ] Preserve `OK_CODE` correctly before clearing it.
- [ ] Demonstrate normal, exit, and cancel function-code processing.

#### `ZGG_GUI_TABLE_CONTROL` - Editable table control

- [ ] Display and edit multiple rows.
- [ ] Vertical and horizontal scrolling.
- [ ] Current-line and visible-line handling.
- [ ] Row selection and mark columns.
- [ ] Insert, append, copy, and delete rows.
- [ ] Validate individual cells and complete rows.
- [ ] Enable or disable cells dynamically.
- [ ] Keep the cursor and scroll position after refresh.

#### `ZGG_GUI_TABSTRIP` - Dynpro tabstrip control

- [ ] Tabs backed by separate subscreens.
- [ ] Server-side tab paging.
- [ ] Client-side tab paging if supported by the target release.
- [ ] Dynamic tab titles and tab visibility.
- [ ] Correct PBO and PAI processing for the active subscreen.

#### `ZGG_GUI_SUBSCREENS` - Reusable subscreen areas

- [ ] Static subscreen embedding.
- [ ] Dynamic replacement of the subscreen program and number.
- [ ] Multiple subscreen areas on one parent screen.
- [ ] Data exchange between parent screen and subscreen.
- [ ] Navigation restrictions inside subscreen flow logic.

#### `ZGG_GUI_GUI_STATUS` - Menus, toolbars, and function keys

- [ ] Menu bar with nested menu entries and separators.
- [ ] Standard toolbar functions.
- [ ] Application toolbar buttons with icons and quick info.
- [ ] Function-key assignments.
- [ ] Static and dynamic GUI titles.
- [ ] Dynamically exclude, enable, or disable functions.
- [ ] Context menus created with `CL_CTMENU`.
- [ ] Standard Back, Exit, and Cancel behavior.

#### `ZGG_GUI_DIALOGS_HELP` - Dialog screens, messages, F1, and F4

- [ ] Modal dialog screen using `CALL SCREEN ... STARTING AT ... ENDING AT`.
- [ ] Standard confirmation, information, and value-entry popups.
- [ ] Safe message types and status-bar messages.
- [ ] Progress indication with `CL_PROGRESS_INDICATOR=>PROGRESS_INDICATE`
  without blocking normal cancellation.
- [ ] DDIC search help and custom process-on-value-request logic.
- [ ] DDIC documentation and custom process-on-help-request logic.
- [ ] Return selected values and distinguish confirm, cancel, and close.

### 30. Control Framework Containers

#### `ZGG_GUI_CUSTOM_CONTAINER` - Custom container

- [ ] Embed a control in a Screen Painter custom-control area.
- [ ] Compare a custom container with `CL_GUI_CONTAINER=>SCREEN0` and
  `DEFAULT_SCREEN`.
- [ ] Link a container by program, screen, custom-control name, or parent.
- [ ] Compare container lifetime modes.
- [ ] Resize the screen and child control.
- [ ] Replace or recreate the hosted child safely.

#### `ZGG_GUI_DOCKING_CONTAINER` - Docking container

- [ ] Dock on the left, right, top, and bottom edges.
- [ ] Change extension and alignment at runtime.
- [ ] Allow detach and reattach where supported.
- [ ] Handle resize and close events.

#### `ZGG_GUI_SPLITTER_CONTAINER` - Splitter containers

- [ ] Horizontal and vertical splits.
- [ ] Nested `CL_GUI_SPLITTER_CONTAINER` instances.
- [ ] `CL_GUI_EASY_SPLITTER_CONTAINER` comparison.
- [ ] Fixed, relative, minimum, and hidden pane sizes.
- [ ] Row and column sizing modes, sash visibility, and border settings.
- [ ] Read current row heights and column widths after interactive resizing.
- [ ] Place a different working control in each cell.

#### `ZGG_GUI_DIALOG_CONTAINER` - Modeless dialog container

- [ ] Create `CL_GUI_DIALOGBOX_CONTAINER`.
- [ ] Host a real child control.
- [ ] Move, resize, close, and recreate the dialog.
- [ ] Coordinate dialog events with the owning dynpro.

#### `ZGG_GUI_COMPOSITE` - Workbench-style composition

- [ ] Navigation tree in a left pane.
- [ ] ALV grid in a main pane.
- [ ] Text or HTML details in a lower pane.
- [ ] Toolbar commands affecting the active child control.
- [ ] Cross-control selection events and drag-and-drop.
- [ ] Persist splitter proportions for the current session.

### 40. Individual GUI Controls

#### `ZGG_GUI_PICTURE` - Picture control

- [ ] Load a MIME repository or URL-based image.
- [ ] Compare synchronous and asynchronous URL loading.
- [ ] Display supported bitmap formats.
- [ ] Stretch, fit, center, and keep-aspect display modes.
- [ ] Toggle the 3D border.
- [ ] React to picture clicks where supported.
- [ ] Clear and reload the image.
- [ ] Handle unavailable or invalid image sources.

#### `ZGG_GUI_TEXTEDIT` - Text edit control

- [ ] Set and retrieve text as a table and as a stream.
- [ ] Editable and read-only modes.
- [ ] Word wrap, line wrap, toolbar, and status-bar options.
- [ ] Selection, current line, and current position.
- [ ] Modified-state and text-change handling.
- [ ] Protected text or line areas where supported.
- [ ] Fixed-width and proportional fonts.
- [ ] Delete all text and restore the initial document.
- [ ] Local file load and save through an explicit user-selected path.

#### `ZGG_GUI_HTML_VIEWER` - HTML viewer

- [ ] Load generated HTML with `LOAD_DATA`.
- [ ] Display a URL when frontend security permits it.
- [ ] Handle `SAPEVENT` links and normal hyperlinks.
- [ ] Provide images and related resources to generated HTML.
- [ ] Compare `LOAD_DATA` plus `SHOW_URL` with direct `SHOW_DATA`.
- [ ] Read the current URL and configure viewer UI flags.
- [ ] Navigate backward, forward, home, and refresh.
- [ ] Close the current document and release its resources.
- [ ] Document rendering and security differences between frontends.
- [ ] Avoid relying on deprecated browser-specific behavior.

#### `ZGG_GUI_ABAP_BROWSER` - ABAP browser helper

- [ ] Display an HTML string with `CL_ABAP_BROWSER=>SHOW_HTML`.
- [ ] Display XML supplied as both `STRING` and `XSTRING`.
- [ ] Compare fullscreen, supplied-container, and dialog display modes.
- [ ] Set a title and demonstrate the printing option where supported.
- [ ] Handle malformed or empty content without terminating the caller.

#### `ZGG_GUI_TOOLBAR` - Toolbar control

- [ ] Normal, toggle, menu, and button-with-menu items.
- [ ] Separators, icons, quick info, and disabled buttons.
- [ ] Dynamic insert, delete, enable, and check state.
- [ ] Function-selected and dropdown-clicked events.
- [ ] Context menus and submenus built with `CL_CTMENU`.
- [ ] Static context-menu tables, button groups, visibility, and state changes.

#### `ZGG_GUI_CALENDAR` - Calendar control

- [ ] Single-date and date-range selection.
- [ ] Multi-selection where supported.
- [ ] Navigate between months and years.
- [ ] Mark dates and display day information.
- [ ] Selection and view-change events.
- [ ] Locale-dependent first day, names, and date formatting.

#### `ZGG_GUI_TREES` - Tree control family

- [ ] Simple tree using `CL_SIMPLE_TREE_MODEL`.
- [ ] List tree using `CL_LIST_TREE_MODEL`.
- [ ] Column tree using `CL_COLUMN_TREE_MODEL`.
- [ ] Compare `CL_GUI_SIMPLE_TREE`, `CL_GUI_LIST_TREE`, and
  `CL_GUI_COLUMN_TREE` with their tree-model counterparts.
- [ ] Exercise inherited `CL_TREE_CONTROL_BASE` selection, visibility, and
  expanded-node APIs.
- [ ] Exercise `CL_ITEM_TREE_CONTROL` behavior through a column or list tree.
- [ ] Add, update, move, expand, collapse, and delete nodes.
- [ ] Icons, checkboxes, item buttons, editable items, item styles, and multiple
  columns.
- [ ] Hierarchy headers, column widths, hidden columns, and header events.
- [ ] Node and item selection, chosen state, double-click, context menu, and key
  events.
- [ ] Lazy loading of child nodes.
- [ ] Single- and multi-item drag-and-drop within a tree and to another control.

#### `ZGG_GUI_DYNAMIC_DOCUMENT` - Dynamic Documents

- [ ] Create a document and display it in an HTML viewer.
- [ ] Headings, text, icons, links, and formatted areas.
- [ ] Tables and form areas.
- [ ] Buttons, input elements, and select elements.
- [ ] Background pictures, document merging, and vertical splitting.
- [ ] Table row and column styles.
- [ ] Print a generated document.
- [ ] Handle document events.
- [ ] Refresh parts of a document without rebuilding unrelated state.

#### `ZGG_GUI_TIMER` - Frontend timer

- [ ] Create and start `CL_GUI_TIMER`.
- [ ] Handle repeated timer events.
- [ ] Start, stop, and change the interval.
- [ ] Refresh a visible control from timer events.
- [ ] Prevent duplicate timers and free the timer on exit.

### 50. SALV and ALV

#### `ZGG_GUI_SALV_TABLE` - Read-only SALV table

- [ ] Automatic column generation.
- [ ] Column texts, visibility, width, alignment, and technical columns.
- [ ] Currency, quantity, sign, zero, edit-mask, key, color, cell-type,
  exception, and hyperlink column settings.
- [ ] Standard functions, sorting, filtering, and aggregation.
- [ ] Add and remove custom functions and handle `ADDED_FUNCTION`.
- [ ] Layout variants and initial layout keys.
- [ ] Find default and available layouts with `CL_SALV_LAYOUT_SERVICE`,
  including layout F4 help.
- [ ] Striped pattern, optimized width, selection modes, and row marks.
- [ ] Configure hyperlinks through `CL_SALV_HYPERLINKS` and handle link-click
  and double-click events.
- [ ] Top-of-list, end-of-list, and print-specific form elements.
- [ ] Fullscreen, popup, container-based, and offline display.
- [ ] Export the current SALV representation with `TO_XML`.

#### `ZGG_GUI_ALV_GRID` - Basic ALV Grid Control

- [ ] Build a field catalog manually and from DDIC metadata.
- [ ] Pass a stable output table to `SET_TABLE_FOR_FIRST_DISPLAY`.
- [ ] Apply layout and toolbar exclusions.
- [ ] Read and replace frontend field catalogs and layouts.
- [ ] Read and set selected rows, columns, cells, and the current cell.
- [ ] Refresh with stable row and column position.
- [ ] Read and restore scroll information.
- [ ] Sort, filter, subtotal, aggregate, print, and export.
- [ ] Read filtered entries, subtotals, print settings, and sort/filter criteria.
- [ ] Change the grid title, ready-for-input state, and border.
- [ ] Save and load layout variants.

#### `ZGG_GUI_ALV_DYNAMIC` - Dynamic ALV output tables

- [ ] Define an LVC field catalog without a static output structure.
- [ ] Create the output table with
  `CL_ALV_TABLE_CREATE=>CREATE_DYNAMIC_TABLE`.
- [ ] Populate the generated table safely through data references and field
  symbols.
- [ ] Add the optional style table and use the returned style-field name.
- [ ] Display and edit the generated table in `CL_GUI_ALV_GRID`.

#### `ZGG_GUI_ALV_VARIANTS` - Direct ALV variant handling

- [ ] Construct `CL_ALV_VARIANT` with output table, field catalog, layout, and
  variant key.
- [ ] Read variant information and the stored field catalog.
- [ ] Apply, save, and switch between sample-owned variants.
- [ ] Delete only variants created by this sample after explicit confirmation.
- [ ] Clean up sample variants and leave unrelated user variants untouched.

#### `ZGG_GUI_ALV_EDIT` - Editable ALV grid

- [ ] Editable columns and individual editable cells.
- [ ] Checkbox, dropdown, button, and hotspot cells.
- [ ] Custom F4 help.
- [ ] Register edit events and call `CHECK_CHANGED_DATA`.
- [ ] Handle `DATA_CHANGED` and `DATA_CHANGED_FINISHED`.
- [ ] Validate input with `CL_ALV_CHANGED_DATA_PROTOCOL`.
- [ ] Add and display protocol entries, modify cells and styles, retrieve cell
  values, and refresh the protocol.
- [ ] Insert, copy, and delete rows.
- [ ] Detect, save, and discard changes without database updates.

#### `ZGG_GUI_ALV_FORMAT` - ALV presentation features

- [ ] Row, column, and cell colors.
- [ ] Cell styles, disabled cells, emphasized cells, and buttons.
- [ ] Icons, symbols, traffic lights, and exception fields.
- [ ] Currency, quantity, unit, date, time, and decimal formatting.
- [ ] Merged headers or column groups where supported.
- [ ] Fixed columns, zebra pattern, totals, and subtotals.

#### `ZGG_GUI_ALV_EVENTS` - ALV interaction and extension

- [ ] Double-click, hotspot, user-command, and selection events.
- [ ] Handle before- and after-user-command, F1, F4, button, menu, and subtotal
  text events.
- [ ] Add custom toolbar functions.
- [ ] Modify the context menu.
- [ ] Delayed selection-change events.
- [ ] Drag-and-drop between rows and controls.
- [ ] Print and top-of-page events where applicable.
- [ ] System-event versus application-event behavior.

#### `ZGG_GUI_ALV_TREE` - ALV tree control

- [ ] Hierarchical nodes with ALV columns.
- [ ] Folder and leaf nodes.
- [ ] Node and item events.
- [ ] Dynamic node loading.
- [ ] Toolbar and context-menu extensions.
- [ ] Hierarchy headers, help fields, optimized columns, and calculated values.
- [ ] Read and change nodes, items, checked items, parents, children, and
  subtrees.
- [ ] Expand, collapse, select, retain the top node, and refresh while retaining
  state.

#### `ZGG_GUI_SALV_TREE` - SALV tree

- [ ] Create and populate a `CL_SALV_TREE` hierarchy.
- [ ] Configure hierarchy and data columns.
- [ ] Standard functions and selections.
- [ ] Link-click and double-click events.
- [ ] Compare capabilities and restrictions with the ALV tree control.

#### `ZGG_GUI_SALV_HIERSEQ` - Hierarchical-sequential SALV

- [ ] Header and item tables with key relationships.
- [ ] Separate header and item column configuration.
- [ ] Sorting, filtering, aggregation, and events.
- [ ] Use cases and limitations compared with trees and ordinary tables.

### 60. Frontend Integration, Optional Controls, and Legacy UI

#### `ZGG_GUI_FRONTEND_SERVICES` - SAP GUI frontend services

- [ ] File-open, file-save, and directory-selection dialogs.
- [ ] Upload and download text and binary data.
- [ ] Check file and directory existence and read file sizes.
- [ ] Copy and delete files inside a sample-owned temporary directory.
- [ ] List, create, select, change, and delete sample-owned directories.
- [ ] Read and write clipboard text.
- [ ] Query frontend type, platform, GUI version, computer name, drive type,
  path separator, and capabilities.
- [ ] Read the temporary, desktop, system, SAP GUI work, and default
  upload/download directories.
- [ ] Demonstrate a read-only registry lookup on SAP GUI for Windows.
- [ ] Open a user-confirmed local file or URL.
- [ ] Handle unavailable GUI, background execution, and security rejection.

#### `ZGG_GUI_DRAG_DROP` - Cross-control drag-and-drop

- [ ] Define `CL_DRAGDROP` behavior objects, flavors, effects, and handles.
- [ ] Reorder rows in an ALV grid.
- [ ] Reparent tree nodes.
- [ ] Transfer an item between a tree and an ALV grid.
- [ ] Transfer application data through `CL_DRAGDROPOBJECT`.
- [ ] Accept, abort, reject, and undo drops.
- [ ] Display source, target, flavor, and event sequence.

#### `ZGG_GUI_ILI_DRAGDROP` - Interactive drag and resize control

- [ ] Create `CL_GUI_ILIDRAGNDROP_CONTROL` in a container.
- [ ] Start dragging in move, horizontal resize, vertical resize, and combined
  resize modes.
- [ ] Show, hide, position, and resize the interactive region.
- [ ] Handle dropped and resized events.
- [ ] Add, display, clear, and handle the control's internal context menu.

#### `ZGG_GUI_CLASSIC_LIST` - Classic and interactive lists

- [ ] `WRITE`, `ULINE`, `SKIP`, `FORMAT`, colors, icons, and hotspots.
- [ ] Page headings, page footings, and line formatting.
- [ ] `AT LINE-SELECTION` and secondary lists.
- [ ] `AT USER-COMMAND` with a list GUI status.
- [ ] `READ LINE`, `MODIFY LINE`, and scrolling.
- [ ] Spool and background behavior.
- [ ] Clearly label classic list processing as legacy for new development.

#### `ZGG_GUI_OFFICE_INTEGRATION` - Desktop Office Integration

- [ ] Detect availability before creating an Office Integration control.
- [ ] Host a document viewer in a container.
- [ ] Demonstrate a small spreadsheet scenario.
- [ ] Demonstrate a small word-processing or mail-merge scenario if available.
- [ ] Close documents and release automation objects reliably.
- [ ] Label the sample as SAP GUI for Windows and installation dependent.

#### `ZGG_GUI_GRAPHICS` - Graphics and selector controls

- [ ] Demonstrate `CL_GUI_BARCHART` where installed.
- [ ] Demonstrate the available SAP chart or graphics engine.
- [ ] Demonstrate `CL_GUI_SELECTOR` for color selection where installed.
- [ ] Handle control absence by reporting the missing class or capability.
- [ ] Record release and frontend support for each variant.

## Shared Sample Requirements

Every sample must:

- [ ] Start independently from SE38 or from `ZGG_GUI_CATALOG`.
- [ ] Explain its purpose in the program documentation, not in a blocking popup.
- [ ] Use deterministic data and avoid persistent database changes.
- [ ] Provide meaningful initial content immediately after startup.
- [ ] Provide Back, Exit, and Cancel handling consistent with SAP GUI behavior.
- [ ] Display relevant control events in a compact event log.
- [ ] Include at least one state-changing interaction and a Reset function.
- [ ] Preserve useful cursor, selection, and scroll state after refresh.
- [ ] Free frontend controls and event handlers cleanly.
- [ ] Handle missing frontend capabilities without a runtime error.
- [ ] Avoid color as the only indication of status or validation.
- [ ] Use icons with text or quick info where their meaning is not universal.
- [ ] Work at common window sizes and DPI scaling levels.
- [ ] Document any frontend, operating-system, release, or software dependency.

## Delivery Plan

### Phase 1 - Baseline and repository conventions

- [ ] Choose the lowest supported ABAP Platform release.
- [ ] Choose the frontends included in the compatibility promise.
- [ ] Audit standard examples in transactions `DWDM`, `BIBS`, and `SE83`.
- [ ] Review available `BCALV*` demonstration programs.
- [ ] Cross-check the class and type surface in
  [`open-abap-gui`](https://github.com/open-abap/open-abap-gui/tree/main/src).
- [ ] Inventory relevant public subclasses of `CL_GUI_CONTROL` in the target
  systems.
- [ ] Create the naming rules, common demo data, and catalog launcher.

### Phase 2 - Native SAP GUI foundations

- [ ] Implement all selection-screen samples.
- [ ] Implement the classic dynpro element and flow samples.
- [ ] Implement table control, tabstrip, subscreen, GUI status, dialog, and help
  samples.
- [ ] Establish the common event-log and reset patterns.

### Phase 3 - Containers and basic controls

- [ ] Implement all four container families.
- [ ] Implement picture, text edit, HTML viewer, toolbar, and calendar samples.
- [ ] Implement the ABAP browser helper sample.
- [ ] Implement tree models and low-level tree comparisons.
- [ ] Implement Dynamic Documents and timer samples.

### Phase 4 - ALV and composed applications

- [ ] Implement SALV table and the basic ALV grid.
- [ ] Add dynamic tables, editing, formatting, validation, variants, and events.
- [ ] Implement ALV tree, SALV tree, and hierarchical-sequential SALV.
- [ ] Build the workbench-style composite sample and cross-control drag-and-drop.

### Phase 5 - Compatibility and optional integrations

- [ ] Add frontend services with security-aware error handling.
- [ ] Add generic and ILI-specific drag-and-drop samples.
- [ ] Add classic list processing and mark it as legacy.
- [ ] Add Office Integration only on a suitable Windows test environment.
- [ ] Add installed graphics controls behind runtime capability checks.

### Phase 6 - Verification and documentation

- [ ] Run syntax checks and ATC on the lowest supported release.
- [ ] Test every core sample on each supported SAP GUI frontend.
- [ ] Test keyboard navigation, focus order, resizing, DPI scaling, and high
  contrast.
- [ ] Verify that canceling file dialogs, popups, and edits leaves consistent
  state.
- [ ] Capture one representative screenshot for each sample.
- [ ] Complete the compatibility matrix and document known limitations.
- [ ] Verify that all reports return cleanly to `ZGG_GUI_CATALOG`.

## Definition of Done

The catalog is complete when every core program is runnable, documented, and
verified on the declared minimum release; every public control family in scope
has a representative sample; optional and legacy programs are clearly labeled;
and the launcher lists and runs every sample.

## SAP References

- [Classic dynpro screen elements](https://help.sap.com/docs/SAP_NETWEAVER_731_BW_ABAP/f68e489816e043f1add91d69a6842931/4a43ad1d8cd9044fe10000000a421937.html)
- [SAP Control Framework overview and control list](https://help.sap.com/docs/SUPPORT_CONTENT/abap/3353523982.html)
- [SAP Control Framework introduction](https://help.sap.com/docs/ABAP_PLATFORM_NEW/70396d7dec4c4f19b9ca3b2e47559d12/4d354f422d830b4ae10000000a42189e.html)
- [Selection-screen elements](https://help.sap.com/docs/SUPPORT_CONTENT/abap/3353524274.html)
- [Working with the ALV Grid Control](https://help.sap.com/docs/ABAP_PLATFORM_NEW/70396d7dec4c4f19b9ca3b2e47559d12/4ebd16291041389ee10000000a421937.html)
- [Classic list processing](https://help.sap.com/docs/SUPPORT_CONTENT/abap/3353525729.html)
- [`open-abap-gui` source inventory](https://github.com/open-abap/open-abap-gui/tree/main/src)
