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

## Compatibility Baseline

- Minimum source level: classic on-premise ABAP Platform 7.50 syntax.
- Primary interactive frontend: SAP GUI for Windows.
- SAP GUI for Java and SAP GUI for HTML: best effort for ordinary dynpro,
  selection-screen, list, and web-compatible controls; no compatibility claim
  is made until Phase 6 testing is complete.
- Windows-only or installed-software controls: runtime capability check plus a
  non-terminating diagnostic fallback is mandatory.
- open-abap: syntax and API-surface validation only. Runtime stubs and missing
  classes are tracked in `ANORMALIES.md`.

## Progress Tracking

- Change an inventory or delivery-plan item to `[x]` only after its repository
  artifacts implement the described behavior and the full `npm test` lint run
  passes.
- Leave partially implemented, unverified, or planned behavior as `[ ]`; do not
  mark an entire report complete merely because its initial source file exists.
- Update this file in the same change that completes a step so the checklist is
  the implementation status source.
- Native-SAP behavior may be marked complete when it is implemented with a
  graceful capability check even if open-abap cannot execute it. The missing or
  different open-abap behavior must then be recorded in `ANORMALIES.md`.

## Program Inventory

### 00. Catalog and Control Framework Fundamentals

#### `ZGG_GUI_CATALOG` - Sample launcher

- [x] List every sample by category, title, and program name.
- [x] Launch executable reports and return to the catalog afterward.

#### `ZGG_GUI_CFW_BASICS` - Control Framework lifecycle

- [x] Create a control once during PBO and reuse it on later round trips.
- [x] Register and handle system and application events.
- [x] Demonstrate `CL_GUI_CFW=>DISPATCH` and `CL_GUI_CFW=>FLUSH`.
- [x] Demonstrate `SET_NEW_OK_CODE`, `UPDATE_VIEW`, and metric-to-pixel
  conversion.
- [x] Set focus and inspect the active control.
- [x] Check validity and frontend technology flags through `CL_GUI_OBJECT`.
- [x] Set visibility, enablement, alignment, position, width, and height through
  common `CL_GUI_CONTROL` methods.
- [x] Refresh frontend state without recreating the control.
- [x] Free controls in the correct child-to-parent order.
- [x] Handle Control Framework and automation errors.
- [x] Display an event log that makes PBO, PAI, and control events visible.

### 10. Selection Screens

#### `ZGG_GUI_SEL_FIELDS` - Parameter field variants

- [x] Character, numeric, date, time, quantity, currency, and boolean fields.
- [x] Checkbox and radio-button group parameters.
- [x] Dropdown list box populated through `VRM_SET_VALUES`.
- [x] Obligatory, lowercase, visible-length, memory-ID, and default values.
- [x] DDIC-bound labels, conversion exits, search help, and parameter IDs.
- [x] Password-style input where supported and appropriate.

#### `ZGG_GUI_SEL_RANGES` - Select-options and ranges

- [x] Single values, intervals, patterns, inclusions, and exclusions.
- [x] Multiple-selection dialog.
- [x] `NO-EXTENSION`, `NO INTERVALS`, and `OBLIGATORY` variants.
- [x] Default values and default ranges.
- [x] Restriction with `SELECT_OPTIONS_RESTRICT`.
- [x] Display the resulting range table after execution.

#### `ZGG_GUI_SEL_LAYOUT` - Selection-screen layout

- [x] Framed and unframed blocks.
- [x] Comments, horizontal lines, blank lines, and explicit positions.
- [x] Multiple elements on one line.
- [x] Selection-screen pushbuttons with user commands.
- [ ] Application-toolbar function keys. Not covered: labelling a
      `SELECTION-SCREEN FUNCTION KEY` requires `SSCRFIELDS-FUNCTXT_nn`, and
      `SSCRFIELDS` is deliberately unused in this repository. An icon
      pushbutton carries the same action instead.
- [x] Icons on selection-screen elements.

#### `ZGG_GUI_SEL_DYNAMIC` - Dynamic selection screens

- [x] Group elements with `MODIF ID`.
- [x] Change input, output, active, invisible, required, and intensified state.
- [x] React to radio buttons, checkboxes, list boxes, and pushbuttons.
- [x] Demonstrate `AT SELECTION-SCREEN OUTPUT`.
- [x] Field, block, and radio-group validation events.
- [x] Custom value-request and help-request handlers.
- [x] Place the cursor on the field that failed validation.

#### `ZGG_GUI_SEL_TABS` - Selection-screen subscreens and tabs

- [x] Define selection screens as subscreens.
- [x] Create a tabbed block with at least three pages.
- [x] Switch pages through user commands.
- [x] Preserve field values while switching tabs.
- [x] Validate active and inactive tab contents correctly.

#### `ZGG_GUI_MODAL_SELSCREEN` - Additional selection screens as windows

- [x] Define additional selection screens with
  `SELECTION-SCREEN BEGIN OF SCREEN ... AS WINDOW`.
- [x] Call a screen as a modal window with `STARTING AT` and `ENDING AT`, and
  compare it with the fullscreen call of the same screen.
- [x] Distinguish Execute, Cancel, and exit commands through `SY-SUBRC` and
  `AT SELECTION-SCREEN ON EXIT-COMMAND`.
- [x] Validate a field and a block of the called screen and place the cursor on
  the rejected field.
- [x] Modify only the fields of the screen currently being sent in
  `AT SELECTION-SCREEN OUTPUT`.
- [x] Keep the values entered on the called screens for the report execution.

#### `ZGG_GUI_SEL_VARIANTS` - Selection variants and report calls

- [x] Offer the variant catalog as value help for a variant parameter.
- [x] Read the stored contents of a variant and list every selection entry.
- [x] Create and update a sample-owned `GG_` variant from the current selection
  values after an explicit confirmation.
- [x] Delete only sample-owned variants, and only after confirmation.
- [x] Start another report with `WITH SELECTION-TABLE` and with
  `VIA SELECTION-SCREEN`.
- [x] Start a report with `USING SELECTION-SET` so the called report applies the
  stored variant itself.
- [ ] Exercise variant value help, creation, update, and deletion on the
  declared native SAP baseline.

#### `ZGG_GUI_SEL_FREE` - Dynamic selections

- [x] Build a dynamic selection with `FREE_SELECTIONS_INIT` from an offered
  table and a preselected field list.
- [x] Display `FREE_SELECTIONS_DIALOG` as a modal window and as a full screen
  with the field tree visible.
- [x] Return the number of active fields, the field ranges, and the WHERE
  clauses, and display all three.
- [x] Convert the returned ranges back into a WHERE clause with
  `FREE_SELECTIONS_RANGE_2_WHERE`.
- [x] Keep the dynamic selection between dialog calls and reset it on request.
- [x] Read no data: only selection metadata and the generated selection are
  shown, so the sample stays free of database access.
- [ ] Exercise the dynamic-selection dialog on the declared native SAP baseline.

### 20. Classic Dynpro Elements

#### `ZGG_GUI_DYNPRO_ELEMENTS` - Screen Painter element gallery

- [x] Static text fields and input/output fields.
- [x] Output-only, required, invisible, and intensified fields.
- [x] Date, time, numeric, quantity, currency, and masked templates, including
  explicit `QUAN`/`UNIT` and `CURR`/`CUKY` reference-field pairs.
- [x] Dropdown list boxes.
- [x] Checkboxes and radio-button groups with and without function codes.
- [x] Text and icon pushbuttons.
- [x] Group boxes and framed areas.
- [x] Status icons with text and quick info.
- [x] Demonstrate field attributes inherited from DDIC references.

#### `ZGG_GUI_DYNPRO_FLOW` - PBO, PAI, and dynamic field behavior

- [x] PBO and PAI module sequence.
- [x] `FIELD`, `CHAIN`, and `ENDCHAIN` validation.
- [x] `ON INPUT`, `ON REQUEST`, and chain-level validation.
- [x] `LOOP AT SCREEN` and `MODIFY SCREEN`.
- [x] Set and read the cursor position.
- [x] Preserve `OK_CODE` correctly before clearing it.
- [x] Demonstrate normal, exit, and cancel function-code processing.

#### `ZGG_GUI_TABLE_CONTROL` - Editable table control

- [x] Display and edit multiple rows.
- [x] Vertical and horizontal scrolling.
- [x] Current-line and visible-line handling.
- [x] Row selection and mark columns.
- [x] Insert, append, copy, and delete rows.
- [x] Validate individual cells and complete rows.
- [x] Enable or disable cells dynamically.
- [x] Keep the cursor and scroll position after refresh.

#### `ZGG_GUI_TABSTRIP` - Dynpro tabstrip control

- [x] Tabs backed by separate subscreens.
- [x] Server-side tab paging.
- [x] Client-side tab paging if supported by the target release.
- [x] Dynamic tab titles and tab visibility.
- [x] Correct PBO and PAI processing for the active subscreen.

#### `ZGG_GUI_SUBSCREENS` - Reusable subscreen areas

- [x] Static subscreen embedding.
- [x] Dynamic replacement of the subscreen program and number.
- [x] Multiple subscreen areas on one parent screen.
- [x] Data exchange between parent screen and subscreen.
- [x] Navigation restrictions inside subscreen flow logic.

#### `ZGG_GUI_GUI_STATUS` - Menus, toolbars, and function keys

- [x] Menu bar with nested menu entries and separators.
- [x] Standard toolbar functions.
- [x] Application toolbar buttons with icons and quick info.
- [x] Function-key assignments.
- [x] Static and dynamic GUI titles.
- [x] Dynamically exclude, enable, or disable functions.
- [x] Context menus created with `CL_CTMENU`.
- [x] Standard Back, Exit, and Cancel behavior.

#### `ZGG_GUI_DIALOGS_HELP` - Dialog screens, messages, F1, and F4

- [x] Modal dialog screen using `CALL SCREEN ... STARTING AT ... ENDING AT`.
- [x] Standard confirmation, information, and value-entry popups.
- [x] Safe message types and status-bar messages.
- [x] Progress indication with `CL_PROGRESS_INDICATOR=>PROGRESS_INDICATE`
  without blocking normal cancellation.
- [x] DDIC search help and custom process-on-value-request logic.
- [x] DDIC documentation and custom process-on-help-request logic.
- [x] Return selected values and distinguish confirm, cancel, and close.

#### `ZGG_GUI_NAVIGATION` - Screen sequences and navigation statements

- [x] `CALL SCREEN` stacking and continuation after the calling statement.
- [x] `SET SCREEN` with `LEAVE SCREEN` as screen replacement, and `SET SCREEN 0`
  compared with `LEAVE TO SCREEN 0`.
- [x] `LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN` from PAI and from PBO.
- [x] `SUPPRESS DIALOG` for a screen that only switches to list processing.
- [x] `SET PARAMETER ID` and `GET PARAMETER ID` through SAP memory.
- [x] `SUBMIT ... AND RETURN` and `CALL TRANSACTION ... AND SKIP FIRST SCREEN`
  behind a confirmation and an `S_TCODE` authority check.
- [x] `LEAVE PROGRAM` and consistent Back, Exit, and Cancel handling on every
  screen level.
- [x] Display the current screen, the call level, and a navigation log.

#### `ZGG_GUI_POPUPS` - Standard popup dialogs

- [x] Two-button confirmation with icons, quick info, and a default button.
- [x] Confirmation with a Cancel button and the three possible answers.
- [x] Information popup that changes no application state.
- [x] Typed value entry with `POPUP_GET_VALUES` for character, date, and time.
- [x] Obligatory field, suppressed value help, and canceled value entry.
- [x] Row selection with `POPUP_WITH_TABLE_DISPLAY` and its returned index.
- [x] Month selection with `POPUP_TO_SELECT_MONTH`.
- [x] Message-based dialogs of types I, W, and S next to the function-module
  popups.

Not covered: `POPUP_TO_DECIDE`, `POPUP_TO_DECIDE_LIST`, `POPUP_TO_GET_VALUE`,
and the `POPUP_TO_CONFIRM_*` variants. SAP replaces all of them with
`POPUP_TO_CONFIRM`, which the sample shows instead; the report names them as
obsolete on its own list. Value help through `F4IF_INT_TABLE_VALUE_REQUEST` is
covered by `ZGG_GUI_DIALOGS_HELP`.

### 30. Control Framework Containers

#### `ZGG_GUI_CUSTOM_CONTAINER` - Custom container

- [x] Embed a control in a Screen Painter custom-control area.
- [x] Compare a custom container with `CL_GUI_CONTAINER=>SCREEN0` and
  `DEFAULT_SCREEN`.
- [x] Link a container by program, screen, and custom-control name.
      `CL_GUI_CONTAINER->LINK` takes no parent; a parent container is supplied
      when the hosted control is constructed.
- [x] Compare container lifetime modes.
- [x] Resize the screen and child control.
- [x] Replace or recreate the hosted child safely.

#### `ZGG_GUI_DOCKING_CONTAINER` - Docking container

- [x] Dock on the left, right, top, and bottom edges.
- [x] Change extension and alignment at runtime.
- [x] Allow detach and reattach where supported.
- [x] Handle resize and close events.

#### `ZGG_GUI_SPLITTER_CONTAINER` - Splitter containers

- [x] Horizontal and vertical splits.
- [x] Nested `CL_GUI_SPLITTER_CONTAINER` instances.
- [x] `CL_GUI_EASY_SPLITTER_CONTAINER` comparison.
- [x] Fixed, relative, minimum, and hidden pane sizes.
- [x] Row and column sizing modes, sash visibility, and border settings.
- [x] Read current row heights and column widths after interactive resizing.
- [x] Place a different working control in each cell.

#### `ZGG_GUI_DIALOG_CONTAINER` - Modeless dialog container

- [x] Create `CL_GUI_DIALOGBOX_CONTAINER`.
- [x] Host a real child control.
- [x] Move, resize, close, and recreate the dialog.
- [x] Coordinate dialog events with the owning dynpro.

#### `ZGG_GUI_COMPOSITE` - Workbench-style composition

- [x] Navigation tree in a left pane.
- [x] ALV grid in a main pane.
- [x] Text or HTML details in a lower pane.
- [x] Toolbar commands affecting the active child control.
- [x] Cross-control selection events and drag-and-drop.
- [x] Persist splitter proportions for the current session.

### 40. Individual GUI Controls

#### `ZGG_GUI_PICTURE` - Picture control

- [x] Load a MIME repository or URL-based image.
- [x] Compare synchronous and asynchronous URL loading.
- [x] Display supported bitmap formats.
- [x] Stretch, fit, center, and keep-aspect display modes.
- [x] Toggle the 3D border.
- [x] Declare and register native `PICTURE_CLICK` and `PICTURE_DBLCLICK`
  handlers in static include `ZGG_NATIVE_PICTURE`, including original image
  coordinates and explicit deregistration.
- [ ] Exercise both picture events on the declared native SAP baseline.
- [x] Clear and reload the image.
- [x] Handle unavailable or invalid image sources.

#### `ZGG_GUI_TEXTEDIT` - Text edit control

- [x] Set and retrieve text as a table and as a stream.
- [x] Editable and read-only modes.
- [x] Word wrap, line wrap, toolbar, and status-bar options.
- [x] Selection, current line, and current position.
- [x] Modified-state and text-change handling.
- [x] Protected text or line areas where supported.
- [x] Fixed-width and proportional fonts.
- [x] Delete all text and restore the initial document.
- [x] Local file load and save through an explicit user-selected path.

#### `ZGG_GUI_HTML_VIEWER` - HTML viewer

- [x] Load generated HTML with `LOAD_DATA`.
- [x] Display a URL when frontend security permits it.
- [x] Handle `SAPEVENT` links and normal hyperlinks.
- [x] Provide images and related resources to generated HTML.
- [x] Compare `LOAD_DATA` plus `SHOW_URL` with direct `SHOW_DATA`.
- [x] Read the current URL and configure viewer UI flags.
- [x] Display a generated PDF document by loading binary data with `LOAD_DATA`
  and the MIME type `application/pdf`.
- [ ] Confirm PDF rendering with the PDF component of each supported frontend.
- [x] Navigate backward, forward, home, and refresh.
- [x] Close the current document and release its resources.
- [x] Document rendering and security differences between frontends.
- [x] Avoid relying on deprecated browser-specific behavior.

#### `ZGG_GUI_ABAP_BROWSER` - ABAP browser helper

- [x] Display an HTML string with `CL_ABAP_BROWSER=>SHOW_HTML`.
- [x] Display XML supplied as both `STRING` and `XSTRING`.
- [x] Compare fullscreen, supplied-container, and dialog display modes.
- [x] Set a title and demonstrate the printing option where supported.
- [x] Handle malformed or empty content without terminating the caller.

#### `ZGG_GUI_TOOLBAR` - Toolbar control

- [x] Normal, toggle, menu, and button-with-menu items.
- [x] Separators, icons, quick info, and disabled buttons.
- [x] Dynamic insert, delete, enable, and check state.
- [x] Function-selected and dropdown-clicked events.
- [x] Context menus and submenus built with `CL_CTMENU`.
- [x] Static context-menu tables, button groups, visibility, and state changes.

#### `ZGG_GUI_CALENDAR` - Calendar control

- [x] Single-date and date-range selection.
- [x] Exercise every native selection form supported by `CL_GUI_CALENDAR`:
  day, week, month, interval, and combined selectable modes. Non-contiguous
  multi-date selection is not part of this control's ABAP interface.
- [x] Navigate between months and years.
- [x] Mark dates and display day information.
- [x] Declare and register native `DATE_SELECTED` and `INFO_REQUEST` handlers
  in static include `ZGG_NATIVE_CALENDAR` and return the selected or requested
  date range to the report.
- [ ] Exercise both calendar events on the declared native SAP baseline.
- [x] Locale-dependent first day, names, and date formatting.

#### `ZGG_GUI_TREES` - Tree control family

#### `ZGG_GUI_TREE_MODELS` - Tree Model family

- [x] Simple tree using `CL_SIMPLE_TREE_MODEL`.
- [x] List tree using `CL_LIST_TREE_MODEL`.
- [x] Column tree using `CL_COLUMN_TREE_MODEL`.
- [x] Compare `CL_GUI_SIMPLE_TREE`, `CL_GUI_LIST_TREE`, and
  `CL_GUI_COLUMN_TREE` with their tree-model counterparts.
- [x] Exercise inherited `CL_TREE_CONTROL_BASE` selection, visibility, and
  expanded-node APIs.
- [x] Exercise `CL_ITEM_TREE_CONTROL` behavior through a column or list tree.
- [x] Add, update, move, expand, collapse, and delete nodes.
- [x] Icons, checkboxes, item buttons, editable items, item styles, and multiple
  columns.
- [x] Hierarchy headers, column widths, hidden columns, and header events.
- [x] Node and item selection, chosen state, double-click, context menu, and key
  events.
- [x] Lazy loading of child nodes.
- [x] Single- and multi-item drag-and-drop within a tree and to another control.

#### `ZGG_GUI_DYNAMIC_DOCUMENT` - Dynamic Documents

- [x] Create a document and display it in an HTML viewer.
- [x] Headings, text, icons, links, and formatted areas.
- [x] Tables and form areas.
- [x] Buttons, input elements, and select elements.
- [x] Background pictures, document merging, and vertical splitting.
- [x] Table row and column styles.
- [x] Print a generated document.
- [x] Declare and register native handlers in static include
  `ZGG_NATIVE_DOCUMENT` for link/button `CLICKED`, input `ENTERED`/`HELP_F1`,
  and select `SELECTED`, including sender values and deregistration before reset
  or exit.
- [ ] Exercise all five Dynamic Document element events on the declared native
  SAP baseline.
- [x] Refresh parts of a document without rebuilding unrelated state.

#### `ZGG_GUI_TIMER` - Frontend timer

- [x] Create and start `CL_GUI_TIMER`.
- [x] Handle repeated timer events.
- [x] Start, stop, and change the interval.
- [x] Refresh a visible control from timer events.
- [x] Prevent duplicate timers and free the timer on exit.

### 50. SALV and ALV

#### `ZGG_GUI_SALV_TABLE` - Read-only SALV table

- [x] Automatic column generation.
- [x] Column texts, visibility, width, alignment, and technical columns.
- [x] Currency, quantity, sign, zero, edit-mask, key, color, cell-type,
  exception, and hyperlink column settings.
- [x] Standard functions, sorting, filtering, and aggregation.
- [x] Add and remove custom functions and handle `ADDED_FUNCTION`.
- [x] Layout variants and initial layout keys.
- [x] Find default and available layouts with `CL_SALV_LAYOUT_SERVICE`,
  including layout F4 help.
- [x] Striped pattern, optimized width, selection modes, and row marks.
- [x] Configure hyperlinks through `CL_SALV_HYPERLINKS` and handle link-click
  and double-click events.
- [x] Top-of-list, end-of-list, and print-specific form elements.
- [x] Fullscreen, popup, container-based, and offline display.
- [x] Export the current SALV representation with `TO_XML`.

#### `ZGG_GUI_ALV_GRID` - Basic ALV Grid Control

- [x] Build a field catalog manually and from DDIC metadata.
- [x] Pass a stable output table to `SET_TABLE_FOR_FIRST_DISPLAY`.
- [x] Apply layout and toolbar exclusions.
- [x] Read and replace frontend field catalogs and layouts.
- [x] Read and set selected rows, columns, cells, and the current cell.
- [x] Refresh with stable row and column position.
- [x] Read and restore scroll information.
- [x] Sort, filter, subtotal, aggregate, print, and export.
- [x] Read filtered entries, subtotals, print settings, and sort/filter criteria.
- [x] Change the grid title, ready-for-input state, and border.
- [x] Save and load layout variants.

#### `ZGG_GUI_ALV_DYNAMIC` - Dynamic ALV output tables

- [x] Define an LVC field catalog without a static output structure.
- [x] Create the output table with
  `CL_ALV_TABLE_CREATE=>CREATE_DYNAMIC_TABLE`.
- [x] Populate the generated table safely through data references and field
  symbols.
- [x] Add the optional style table and use the returned style-field name.
- [x] Display and edit the generated table in `CL_GUI_ALV_GRID`.

#### `ZGG_GUI_ALV_VARIANTS` - Direct ALV variant handling

- [x] Construct `CL_ALV_VARIANT` with output table, field catalog, layout, and
  variant key.
- [x] Read variant information and the stored field catalog.
- [x] Apply, save, and switch between sample-owned variants.
- [x] Delete only variants created by this sample after explicit confirmation.
- [x] Clean up sample variants and leave unrelated user variants untouched.

#### `ZGG_GUI_ALV_EDIT` - Editable ALV grid

- [x] Editable columns and individual editable cells.
- [x] Checkbox, dropdown, button, and hotspot cells.
- [x] Custom F4 help.
- [x] Register edit events and call `CHECK_CHANGED_DATA`.
- [x] Handle `DATA_CHANGED` and `DATA_CHANGED_FINISHED`.
- [x] Validate input with `CL_ALV_CHANGED_DATA_PROTOCOL`.
- [x] Add and display protocol entries, modify cells and styles, retrieve cell
  values, and refresh the protocol.
- [x] Insert, copy, and delete rows.
- [x] Detect, save, and discard changes without database updates.

#### `ZGG_GUI_ALV_FORMAT` - ALV presentation features

- [x] Row, column, and cell colors.
- [x] Cell styles, disabled cells, emphasized cells, and buttons.
- [x] Icons, symbols, traffic lights, and exception fields.
- [x] Currency, quantity, unit, date, time, and decimal formatting.
- [x] Merged headers or column groups where supported.
- [x] Fixed columns, zebra pattern, totals, and subtotals.

#### `ZGG_GUI_ALV_EVENTS` - ALV interaction and extension

- [x] Double-click, hotspot, and user-command events.
- [x] Handle before- and after-user-command, F1, F4, button, menu, and subtotal
  text events.
- [x] Add custom toolbar functions.
- [x] Modify the context menu.
- [x] Declare and register a native `DELAYED_CHANGED_SEL_CALLBACK` handler in
  static include `ZGG_NATIVE_ALV_EVENTS`, preserve it across event-mode
  recreation, and deregister on exit.
- [ ] Exercise delayed selection changes on the declared native SAP baseline.
- [x] Drag-and-drop between rows and controls.
- [x] Print and top-of-page events where applicable.
- [x] System-event versus application-event behavior.

#### `ZGG_GUI_ALV_TREE` - ALV tree control

- [x] Hierarchical nodes with ALV columns.
- [x] Folder and leaf nodes.
- [x] Node and item events.
- [x] Dynamic node loading.
- [x] Toolbar extension and context-menu selection events.
- [x] Declare and register a native `NODE_CONTEXT_MENU_REQUEST` handler in
  static include `ZGG_NATIVE_ALV_TREE` that preserves existing frontend
  registrations and adds two commands.
- [ ] Exercise the context-menu request and both injected commands on the
  declared native SAP baseline.
- [x] Hierarchy headers, help fields, optimized columns, and calculated values.
- [x] Read and change nodes, items, checked items, parents, children, and
  subtrees.
- [x] Expand, collapse, select, retain the top node, and refresh while retaining
  state.

#### `ZGG_GUI_SALV_TREE` - SALV tree

- [x] Create and populate a `CL_SALV_TREE` hierarchy.
- [x] Configure hierarchy and data columns.
- [x] Standard functions and selections.
- [x] Declare and register native SALV Tree link-click and double-click handlers
  in static include `ZGG_NATIVE_SALV_TREE`, including node/column payloads and
  deregistration on exit.
- [ ] Exercise SALV Tree link-click and double-click on the declared native SAP
  baseline.
- [x] Compare capabilities and restrictions with the ALV tree control.

#### `ZGG_GUI_SALV_HIERSEQ` - Hierarchical-sequential SALV

- [x] Header and item tables with key relationships.
- [x] Separate header and item column configuration.
- [x] Sorting, filtering, and aggregation.
- [x] Declare and register native hierarchical-sequential link-click and
  double-click handlers in static include `ZGG_NATIVE_SALV_HSEQ`, including
  level/row/column payloads and deregistration.
- [ ] Exercise both hierarchical-sequential SALV events on the declared native
  SAP baseline.
- [x] Use cases and limitations compared with trees and ordinary tables.

### 60. Frontend Integration, Optional Controls, and Legacy UI

#### `ZGG_GUI_FRONTEND_SERVICES` - SAP GUI frontend services

- [x] File-open, file-save, and directory-selection dialogs.
- [x] Upload and download text and binary data.
- [x] Check file and directory existence and read file sizes.
- [x] Copy and delete files inside a sample-owned temporary directory.
- [x] List, create, select, change, and delete sample-owned directories.
- [x] Read and write clipboard text.
- [x] Query frontend type, platform, GUI version, computer name, drive type,
  path separator, and capabilities.
- [x] Read the temporary, desktop, system, SAP GUI work, and default
  upload/download directories.
- [x] Demonstrate a read-only registry lookup on SAP GUI for Windows.
- [x] Open a user-confirmed local file or URL.
- [x] Handle unavailable GUI, background execution, and security rejection.

#### `ZGG_GUI_DRAG_DROP` - Cross-control drag-and-drop

- [x] Define `CL_DRAGDROP` behavior objects, flavors, effects, and handles.
- [x] Reorder rows in an ALV grid.
- [x] Reparent tree nodes.
- [x] Transfer an item between a tree and an ALV grid.
- [x] Transfer application data through `CL_DRAGDROPOBJECT`.
- [x] Accept, abort, reject, and undo drops.
- [x] Display source, target, flavor, and event sequence.

#### `ZGG_GUI_ILI_DRAGDROP` - Interactive drag and resize control

- [x] Create `CL_GUI_ILIDRAGNDROP_CONTROL` in a container.
- [x] Start dragging in move, horizontal resize, vertical resize, and combined
  resize modes.
- [x] Show, hide, position, and resize the interactive region.
- [x] Handle dropped and resized events.
- [x] Add, display, clear, and handle the control's internal context menu.

#### `ZGG_GUI_ALV_CLASSIC` - Function-module ALV

- [x] Build a field catalog manually and merge one from the program symbol
  table with `REUSE_ALV_FIELDCATALOG_MERGE`.
- [x] `REUSE_ALV_GRID_DISPLAY` with layout, sort with subtotals, grid title, and
  a layout variant.
- [x] `REUSE_ALV_LIST_DISPLAY` driven by an event table from
  `REUSE_ALV_EVENTS_GET`.
- [x] `REUSE_ALV_HIERSEQ_LIST_DISPLAY` with header table, item table, and key
  information.
- [x] `REUSE_ALV_BLOCK_LIST_INIT`, `_APPEND`, and `_DISPLAY` for two blocks.
- [x] `REUSE_ALV_POPUP_TO_SELECT` returning the selected row.
- [x] PF-status, user-command, top-of-page, and end-of-list callbacks, including
  `REUSE_ALV_COMMENTARY_WRITE` and the standard status of `SAPLKKBL`.
- [x] Layout-variant value help with `REUSE_ALV_VARIANT_F4`.
- [x] Clearly label the function-module ALV as legacy for new development and
  name the SALV and ALV Grid replacements.
- [ ] Exercise every display flavor and every callback on the declared native
  SAP baseline.

#### `ZGG_GUI_CLASSIC_LIST` - Classic and interactive lists

- [x] `WRITE`, `ULINE`, `SKIP`, `FORMAT`, colors, icons, and hotspots.
- [x] Page headings, page footings, and line formatting.
- [x] `AT LINE-SELECTION` and secondary lists.
- [x] `AT USER-COMMAND` with a list GUI status.
- [x] `READ LINE`, `MODIFY LINE`, and scrolling.
- [x] Spool and background behavior.
- [x] Clearly label classic list processing as legacy for new development.

#### `ZGG_GUI_GRAPHICS` - Graphics and selector controls

- [x] Demonstrate `CL_GUI_BARCHART` where installed.
- [x] Demonstrate the available SAP chart or graphics engine.
- [x] Demonstrate `CL_GUI_SELECTOR` for color selection where installed.
- [x] Handle control absence by reporting the missing class or capability.
- [x] Record release and frontend support for each variant.

## `open-abap-gui` Coverage Audit

Coverage was checked against
[commit `7643d3b98058b1c47509e1a42af3187b7f6fbff7`](https://github.com/open-abap/open-abap-gui/tree/7643d3b98058b1c47509e1a42af3187b7f6fbff7/src)
(repository `main` resolved on 2026-08-21), not against a moving branch
reference.

The pinned tree contains 173 source artifacts: 71 class implementations, 6
interfaces, 4 type pools, 86 DDIC definitions, 5 class metadata files, and 1
test include. They map to the runnable catalog as follows:

| Repository family | Covered by |
| --- | --- |
| Control Framework, GUI object/control, base/custom/splitter containers | `ZGG_GUI_CFW_BASICS`, container reports, `ZGG_GUI_COMPOSITE` |
| ABAP browser, HTML, picture, TextEdit, timer, toolbar, progress indicator | Corresponding individual reports and `ZGG_GUI_DIALOGS_HELP` |
| Frontend Services and context menus | `ZGG_GUI_FRONTEND_SERVICES`, toolbar/tree/status reports |
| Column-tree and inherited tree bases | `ZGG_GUI_TREES`, `ZGG_GUI_TREE_MODELS`, `ZGG_GUI_DRAG_DROP` |
| ALV Grid, ALV tree, table creation, variants, event/protocol helpers | `ZGG_GUI_ALV_*` reports and `ZGG_GUI_COMPOSITE` |
| Dynamic Documents classes and SDYDO types | `ZGG_GUI_DYNAMIC_DOCUMENT` |
| Generic and ILI drag/drop classes | `ZGG_GUI_DRAG_DROP`, `ZGG_GUI_ILI_DRAGDROP` |
| SALV table plus column/filter/sort/function/layout/form/event helpers | `ZGG_GUI_SALV_TABLE` |
| SALV constants, exceptions, interfaces, and all LVC/SALV/tree DDIC types | Consumed by SALV/ALV reports; no standalone report by scope |

Three native families used by the catalog have no counterpart at all in the
pinned dependency tree: the `SLIS` type pool with the `REUSE_ALV_*` function
modules, the selection-variant types with the `RS_VARIANT_*` function modules,
and the `RSDS*` dynamic-selection types with the `FREE_SELECTIONS_*` function
modules. They are consumed by `ZGG_GUI_ALV_CLASSIC`, `ZGG_GUI_SEL_VARIANTS`,
and `ZGG_GUI_SEL_FREE` through their static native includes and are recorded in
`ANORMALIES.md`.

No public control class family present in the pinned repository is absent from
the plan. Base classes, marker interfaces, constants, exceptions, type pools,
DDIC structures, class metadata, and tests remain supporting artifacts rather
than receiving artificial standalone programs. Native SAP classes missing from
open-abap, including additional containers, calendars, Tree Models, SALV tree
variants, and graphics controls, are still represented by capability-guarded
samples and recorded in `ANORMALIES.md`.

### Native verification gates

The following feature boxes remain unchecked because their native event type,
DDIC type, or function-module family is absent from the pinned dependency
surface, or because their target interaction has not yet been exercised. The
reports keep the surrounding native behavior and CFW dispatch path. Native-only
declarations are isolated in static include programs, which still have to
activate and run on the declared native baseline.

| Feature | Implemented repository behavior | Native evidence still required |
| --- | --- | --- |
| Picture click/double-click | Static typed handler include, coordinate payload, and cleanup | Click and double-click the rendered fixture on native SAP GUI |
| Calendar selection/view events | Static typed handler include, date-range payload, and cleanup | Select a date/range and request date information on native SAP GUI |
| Dynamic Document element events | Static typed handler include for five element events, sender/value payload, and cleanup | Trigger link, button, Enter, F1, and select events on native SAP GUI |
| Delayed ALV selection | Static typed handler include, delayed event registration, mode recreation, and cleanup | Change selection and observe the callback after the native delay |
| ALV Tree context-menu request | Static typed handler include preserving prior event registrations and adding two commands | Open the node menu and execute both added commands on native SAP GUI |
| SALV Tree link/double-click | Static typed `GET_EVENT` handler include with node/column payload and cleanup | Activate a link item and double-click an item on native SAP GUI |
| SALV hierseq events | Static typed `GET_EVENT` handler include with level/row/column payload and cleanup | Activate the `ITEM_ID` hotspot and double-click both hierarchy levels |
| Function-module ALV | Static SLIS-typed include with five display flavors, field-catalog merge, and four callbacks | Run every flavor, trigger each callback, and use the layout-variant value help |
| Selection variants | Static include with variant catalog, contents, create/update/delete, and the three `SUBMIT` forms | Save, read, start, and delete a `GG_` variant on native SAP GUI |
| Dynamic selections | Static include with `FREE_SELECTIONS_INIT`, dialog as window and full screen, and range-to-WHERE conversion | Enter, extend, and reset a dynamic selection and check the generated WHERE clause |

Do not check these items based only on dynamic RTTI calls or a generic dispatch
return code. Check them after a real handler compiles against the declared
baseline and the relevant native interaction has been exercised.

### Native validation protocol

Run this protocol on the minimum supported ABAP Platform release before
checking any remaining native-only box:

1. Import the same repository revision, activate every object, and run syntax
   checks plus ATC. The local `v750` abaplint gate does not replace this native
   check; mark the native syntax/ATC item only when there are no unresolved
   findings attributable to these samples.
2. Execute `ZGG_GUI_CATALOG`, launch every row, exercise all visible commands,
   Reset/Recreate paths, Back/Exit/Cancel, and return to the catalog. Do not add
   validation fields to the launcher; it remains category/program/title only.
3. For each row in the event table above, activate the owner report and its
   static native include, confirm handler registration, perform every listed
   gesture, and verify the displayed event name plus payload.
4. Repeat ordinary dynpro, selection-screen, list, and supported control
   samples on SAP GUI for Windows, Java, and HTML. Treat unavailable optional
   Windows controls as a pass only when the documented diagnostic fallback is
   non-terminating and accurate.
5. At common compact/large window sizes and supported DPI/high-contrast
   settings, verify that controls resize, text remains visible, focus order and
   keyboard activation work, and no element overlaps another.
6. Cancel every file/directory chooser, print prompt, popup, and pending edit
   once, then verify that owned state and sample files remain consistent.
   Cancel every popup of `ZGG_GUI_POPUPS`, every called selection screen of
   `ZGG_GUI_MODAL_SELSCREEN`, and the dynamic-selection dialog as well, and
   confirm that no `GG_` variant is written when a confirmation is answered
   with Cancel.
7. Capture one representative screenshot per sample after its distinctive
   behavior is visible. Do not check the screenshot item for startup or
   fallback-only images when the native control is available.
8. Audit `DWDM`, `BIBS`, `SE83`, available `BCALV*` reports, and the native
   `CL_GUI_CONTROL` subclass hierarchy. Add any public in-scope control or
   interaction absent from this inventory before checking the audit items.
9. Update the corresponding `[ ]` to `[x]` in this file immediately after the
   successful run. In the same change, add every transpiler/runtime deviation
   or missing open-abap behavior discovered during validation to
   `ANORMALIES.md`; do not wait for the end of Phase 6.

## Shared Sample Requirements

Every sample must:

- [x] Start independently from SE38 or from `ZGG_GUI_CATALOG`.
- [x] Explain its purpose in its `PLAN.md` program section and report-title text
  pool, not in a blocking popup.
- [x] Use deterministic in-memory data and no direct database DML. The ALV
  variant and selection-variant samples are the explicit exceptions: only a
  user-triggered, `GG_`-named sample variant may be persisted, tracked, and
  offered for guarded cleanup, and only after an explicit confirmation.
- [x] Provide meaningful deterministic content or a capability diagnostic
  immediately after startup.
- [x] Provide Back, Exit, and Cancel handling consistent with SAP GUI behavior.
- [x] Display relevant control events in a compact log or status line.
- [x] Include at least one state-changing interaction and a Reset, Restore, or
  Recreate action when the sample owns mutable state; stateless helpers and
  standard selection/list screens use their native reset behavior.
- [x] Preserve useful cursor, selection, and scroll state after refresh where
  the API exposes it: stable ALV/SALV refresh flags, table-control top-line and
  cursor handling, retained Dynamic Document elements, and in-place viewer
  refresh are used instead of unnecessary control reconstruction.
- [x] Free frontend controls and event handlers cleanly.
- [x] Handle missing optional or frontend-varying capabilities without a
  runtime error by using RTTI/dynamic-call guards and diagnostic fallbacks.
  Failure of a mandatory control on the primary SAP GUI for Windows baseline
  remains an execution error rather than being presented as supported.
- [x] Record transpiler/runtime behavior differences and missing open-abap
  functionality in `ANORMALIES.md`, including a minimal reproduction and the
  native SAP behavior expected.
- [x] Avoid color as the only indication of status or validation.
- [x] Use icons with text or quick info where their meaning is not universal,
  keeping quick-info values within native fixed-length parameter limits.
- [x] Exclude Screen Painter icon aliases known to fail native object import;
  repository verification rejects these values before delivery.
- [x] Separate top-level Screen Painter elements that share rows by at least one
  column; repository verification rejects touching or overlapping elements.
- [x] Give top-level `QUAN` and `CURR` fields explicit unit and currency
  references; repository verification checks matching visible reference types.
- [ ] Work at common window sizes and DPI scaling levels.
- [x] Document any frontend, operating-system, release, or software dependency.
- [x] Use static source for all handlers and helper routines; generated
  subroutine pools are prohibited. Native event types, DDIC types, and function
  modules missing from open-abap are isolated in the ten checked
  `ZGG_NATIVE_*` include programs, each owned by exactly one report.

`npm run verify:repo` enforces the independently executable report shape,
catalog parity and schema, screen/XML pairing, dynpro exit paths, event-receiver
cleanup, Screen Painter icon aliases, top-level element spacing, quantity and
currency references, PLAN coverage, anomaly record structure, the
direct-database-DML rule, the generated-subroutine-pool ban, and exact static
native-include ownership and metadata. Behavioral and visual requirements still
require the native checks in Phase 6 and are not inferred from this gate.

`npm run lint` enforces ABAP syntax and API parameter compatibility, including
fixed-length toolbar quick-info arguments.

## Delivery Plan

### Phase 1 - Baseline and repository conventions

- [x] Choose the lowest supported ABAP Platform release.
- [x] Choose the frontends included in the compatibility promise.
- [ ] Audit standard examples in transactions `DWDM`, `BIBS`, and `SE83`.
- [ ] Review available `BCALV*` demonstration programs.
- [x] Cross-check the class and type surface in
  [`open-abap-gui`](https://github.com/open-abap/open-abap-gui/tree/main/src).
- [ ] Inventory relevant public subclasses of `CL_GUI_CONTROL` in the target
  systems.
- [x] Create the naming rules, common demo data, and catalog launcher.

### Phase 2 - Native SAP GUI foundations

- [x] Implement all selection-screen samples.
- [x] Implement the classic dynpro element and flow samples.
- [x] Implement table control, tabstrip, subscreen, GUI status, dialog, and help
  samples.
- [x] Implement additional selection screens as windows, selection variants, and
  dynamic selections.
- [x] Implement screen-sequence navigation and the standard popup gallery.
- [x] Establish the common event-log and reset patterns.

### Phase 3 - Containers and basic controls

- [x] Implement all four container families.
- [x] Implement picture, text edit, HTML viewer, toolbar, and calendar samples.
- [x] Implement the ABAP browser helper sample.
- [x] Implement tree models and low-level tree comparisons.
- [x] Implement Dynamic Documents and timer samples.

### Phase 4 - ALV and composed applications

- [x] Implement SALV table and the basic ALV grid.
- [x] Add dynamic tables, editing, formatting, validation, variants, and events.
- [x] Implement ALV tree, SALV tree, and hierarchical-sequential SALV.
- [x] Build the workbench-style composite sample and cross-control drag-and-drop.

### Phase 5 - Compatibility and optional integrations

- [x] Add frontend services with security-aware error handling.
- [x] Add generic and ILI-specific drag-and-drop samples.
- [x] Add classic list processing and mark it as legacy.
- [x] Add the function-module ALV and mark it as legacy.
- [x] Add installed graphics controls behind runtime capability checks.

### Phase 6 - Verification and documentation

- [x] Run repository syntax and API-surface checks with abaplint configured for
  the declared `v750` source baseline.
- [ ] Activate all objects and run native syntax checks and ATC on the lowest
  supported release.
- [ ] Test every core sample on each supported SAP GUI frontend.
- [ ] Test keyboard navigation, focus order, resizing, DPI scaling, and high
  contrast.
- [ ] Verify that canceling file dialogs, popups, and edits leaves consistent
  state.
- [ ] Capture one representative screenshot for each sample.
- [x] Complete the compatibility matrix and document known limitations.
- [x] Review `ANORMALIES.md` and ensure every observed open-abap deviation is
  recorded with current reproduction and status.
- [ ] Verify that all reports return cleanly to `ZGG_GUI_CATALOG`.

## Definition of Done

The catalog is complete when every core program is runnable, documented, and
verified on the declared minimum release; every public control family in scope
has a representative sample; optional and legacy programs are clearly labeled;
the launcher lists and runs every sample; and all observed transpiler, runtime,
or missing open-abap behavior is recorded in `ANORMALIES.md`.

## SAP References

- [Classic dynpro screen elements](https://help.sap.com/docs/SAP_NETWEAVER_731_BW_ABAP/f68e489816e043f1add91d69a6842931/4a43ad1d8cd9044fe10000000a421937.html)
- [SAP Control Framework overview and control list](https://help.sap.com/docs/SUPPORT_CONTENT/abap/3353523982.html)
- [SAP Control Framework introduction](https://help.sap.com/docs/ABAP_PLATFORM_NEW/70396d7dec4c4f19b9ca3b2e47559d12/4d354f422d830b4ae10000000a42189e.html)
- [Selection-screen elements](https://help.sap.com/docs/SUPPORT_CONTENT/abap/3353524274.html)
- [Working with the ALV Grid Control](https://help.sap.com/docs/ABAP_PLATFORM_NEW/70396d7dec4c4f19b9ca3b2e47559d12/4ebd16291041389ee10000000a421937.html)
- [Classic list processing](https://help.sap.com/docs/SUPPORT_CONTENT/abap/3353525729.html)
- [`open-abap-gui` source inventory](https://github.com/open-abap/open-abap-gui/tree/main/src)
