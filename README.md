# gg-gui

Curated ABAP reports for SAP GUI selection screens, classic dynpros, Control
Framework controls, SALV/ALV, frontend integration, optional desktop controls,
and legacy list processing.

The reports use deterministic in-memory data and are intended to be small,
independent references. `ZGG_GUI_COMPOSITE` is the deliberate exception: it
shows how a navigation tree, toolbar, ALV grid, details editor, splitters, and
drag/drop behavior cooperate in a workbench-style screen.

## Baseline

- Classic on-premise ABAP Platform 7.50 source syntax.
- SAP GUI for Windows is the primary interactive frontend.
- SAP GUI for Java and SAP GUI for HTML behavior is not yet certified.
- Optional graphics controls require their corresponding local Windows
  software/control installation.
- open-abap is used for syntax and API-surface checking. It does not currently
  execute most GUI controls.

## Install and Run

Import the repository with abapGit, then execute `ZGG_GUI_CATALOG` from SE38 or
SA38. Select a program name in the classic list to launch it; returning from the
sample returns to the catalog. Every catalog entry is also an executable report
that can be started directly.

For local static validation:

```text
npm install
npm test
```

`npm test` first runs the repository verifier, then resolves `open-abap-core`
and `open-abap-gui` as API dependencies for linting. The verifier checks
report/catalog parity, the three-field catalog schema, report and screen XML
pairing, dynpro exit paths, event-receiver cleanup, PLAN coverage, anomaly
record structure, and the absence of direct persistent database DML. abaplint
checks ABAP 7.50 syntax, DDIC references,
screen includes, text pools, and abapGit XML consistency. The documented API
coverage audit is pinned to the exact `open-abap-gui` commit in `PLAN.md`.

## Catalog Areas

| Area | Reports |
| --- | --- |
| Framework and containers | CFW lifecycle, custom/docking/splitter/dialog containers, composite workbench |
| Selection screens | fields, ranges, layout, dynamic state, tabbed subscreens |
| Classic dynpro | element gallery, flow logic, table control, tabstrip, subscreens, dialogs/help, GUI status |
| Individual controls | picture, TextEdit, HTML viewer, ABAP browser, toolbar, calendar, timer, Dynamic Documents |
| Trees and drag/drop | low-level tree, Tree Models, generic cross-control drag/drop, ILI move/resize |
| SALV and ALV | SALV table/tree/hierseq, basic/dynamic/edit/format/event/variant ALV, ALV tree |
| Frontend and optional | Frontend Services, graphics/selector controls |
| Legacy | classic interactive list and spool behavior |

The complete per-program feature checklist and current implementation status is
in [PLAN.md](PLAN.md). The launcher intentionally stores only category, program
name, and title; it has no separate catalog metadata schema.

## Compatibility

| Environment | Status |
| --- | --- |
| SAP GUI for Windows on ABAP Platform 7.50+ | Primary target; native execution and visual verification still required |
| SAP GUI for Java | Best effort; Windows-specific controls are unavailable |
| SAP GUI for HTML | Best effort; Control Framework and frontend-service coverage differs |
| open-abap transpiler/runtime | Full repository syntax check; many GUI classes are missing, assertions, or no-op stubs |

Every optional control is created behind a runtime capability check and has a
diagnostic fallback. File mutations in the Frontend Services sample are limited
to a derived `ZGG_GUI_<user>` directory below the frontend temporary directory.
ALV variant cleanup is restricted to sample-owned names after confirmation.

## Known Limitations

Observed missing classes, stubbed methods, event-surface differences, and
runtime assertions in open-abap are recorded in [ANORMALIES.md](ANORMALIES.md).
That filename intentionally follows the requested spelling. Local network or
sandbox failures are not runtime anomalies.

Native SAP syntax/ATC, multi-frontend behavior, DPI/high-contrast layout,
keyboard navigation, dialog cancellation, representative screenshots, and
end-to-end catalog return behavior remain Phase 6 verification work.
