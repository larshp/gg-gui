import { readFileSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const srcDir = join(root, "src");
const files = readdirSync(srcDir).sort();
const read = (path) => readFileSync(path, "utf8");
const fail = (message) => {
  throw new Error(message);
};
const unsupportedScreenIcons = new Set([
  "ICON_BACK",
  "ICON_HIDE",
  "ICON_MINUS",
  "ICON_PICTURE",
  "ICON_PLUS",
  "ICON_SYSTEM_OKAY",
]);
const elementValue = (block, tag) =>
  block.match(new RegExp(`<${tag}>([^<]*)</${tag}>`, "i"))?.[1].trim() ?? "";
const topLevelScreenFields = (dynpro) =>
  [...dynpro.matchAll(/<RPY_DYFATC>([\s\S]*?)<\/RPY_DYFATC>/gi)]
    .map((match) => match[1])
    .filter((field) => elementValue(field, "CONT_TYPE").toUpperCase() === "SCREEN")
    .filter((field) => !["FRAME", "OKCODE"].includes(elementValue(field, "TYPE").toUpperCase()))
    .map((field) => {
      const line = Number.parseInt(elementValue(field, "LINE"), 10);
      const column = Number.parseInt(elementValue(field, "COLUMN"), 10);
      const width = Number.parseInt(
        elementValue(field, "VISLENGTH") || elementValue(field, "LENGTH"),
        10,
      );
      const height = Number.parseInt(elementValue(field, "HEIGHT") || "1", 10);
      return {
        name: elementValue(field, "NAME"),
        format: elementValue(field, "FORMAT").toUpperCase(),
        reference: elementValue(field, "REF_FIELD").toUpperCase(),
        top: line,
        bottom: line + height - 1,
        left: column,
        right: column + width - 1,
      };
    })
    .filter((field) =>
      field.name && [field.top, field.bottom, field.left, field.right].every(Number.isFinite),
    );

const reportFiles = files.filter((name) => /^zgg_gui_.+\.prog\.abap$/i.test(name));
const sampleFiles = reportFiles.filter((name) => name !== "zgg_gui_catalog.prog.abap");
const abapFiles = files.filter((name) => /\.abap$/i.test(name));
const programFor = (name) => name.replace(/\.prog\.abap$/i, "").toUpperCase();
const nativeIncludeOwners = new Map([
  ["ZGG_NATIVE_ALV_EVENTS", "zgg_gui_alv_events.prog.abap"],
  ["ZGG_NATIVE_ALV_TREE", "zgg_gui_alv_tree.prog.abap"],
  ["ZGG_NATIVE_CALENDAR", "zgg_gui_calendar.prog.abap"],
  ["ZGG_NATIVE_DOCUMENT", "zgg_gui_dynamic_document.prog.abap"],
  ["ZGG_NATIVE_PICTURE", "zgg_gui_picture.prog.abap"],
  ["ZGG_NATIVE_SALV_HSEQ", "zgg_gui_salv_hierseq.prog.abap"],
  ["ZGG_NATIVE_SALV_TREE", "zgg_gui_salv_tree.prog.abap"],
]);
const plan = read(join(root, "PLAN.md"));
const anomalies = read(join(root, "ANORMALIES.md"));
const abaplintConfig = read(join(root, "abaplint.jsonc"));
const catalog = read(join(srcDir, "zgg_gui_catalog.prog.abap"));

if (!/"version"\s*:\s*"v750"/.test(abaplintConfig)) {
  fail("abaplint syntax version must remain v750 to match the declared minimum release");
}

for (const file of abapFiles) {
  const source = read(join(srcDir, file));
  if (/\bGENERATE\s+SUBROUTINE\s+POOL\b/i.test(source)) {
    fail(`${file}: generated subroutine pools are not allowed; use static code`);
  }
}

const nativeIncludePrograms = files
  .filter((name) => /^zgg_native_.+\.prog\.abap$/i.test(name))
  .map(programFor)
  .sort();
const requiredNativeIncludes = [...nativeIncludeOwners.keys()].sort();
if (JSON.stringify(nativeIncludePrograms) !== JSON.stringify(requiredNativeIncludes)) {
  fail("Static native include programs do not exactly match the required event includes");
}
for (const [includeProgram, ownerFile] of nativeIncludeOwners) {
  const includeFile = `${includeProgram.toLowerCase()}.prog.abap`;
  const xmlName = includeFile.replace(/\.abap$/i, ".xml");
  if (!files.includes(xmlName)) fail(`${includeProgram}: missing ${xmlName}`);

  const xml = read(join(srcDir, xmlName));
  if (!new RegExp(`<NAME>${includeProgram}</NAME>`, "i").test(xml) ||
      !/<SUBC>I<\/SUBC>/i.test(xml)) {
    fail(`${xmlName}: must describe include program ${includeProgram}`);
  }

  const ownerSource = read(join(srcDir, ownerFile));
  if (!new RegExp(`^\\s*INCLUDE\\s+${includeProgram}\\s*\\.`, "im").test(ownerSource)) {
    fail(`${ownerFile}: missing static include ${includeProgram}`);
  }
}

for (const file of reportFiles) {
  const program = programFor(file);
  const source = read(join(srcDir, file));
  const xmlName = file.replace(/\.abap$/i, ".xml");
  if (!files.includes(xmlName)) fail(`${program}: missing ${xmlName}`);
  if (!new RegExp(`^REPORT\\s+${program}\\b`, "im").test(source)) {
    fail(`${program}: source is not an independently executable report`);
  }

  const xml = read(join(srcDir, xmlName));
  for (const match of xml.matchAll(/<ICON_NAME>([^<]+)<\/ICON_NAME>/gi)) {
    const icon = match[1].trim().toUpperCase();
    if (unsupportedScreenIcons.has(icon)) {
      fail(`${xmlName}: unsupported Screen Painter icon ${icon}`);
    }
  }
  const dynpros = xml.match(/<DYNPROS>([\s\S]*?)<\/DYNPROS>/i)?.[1] ?? "";
  for (const match of dynpros.matchAll(/<item>([\s\S]*?)<\/item>/gi)) {
    const dynpro = match[1];
    const screen = elementValue(dynpro.match(/<HEADER>([\s\S]*?)<\/HEADER>/i)?.[1] ?? "", "SCREEN");
    const screenFields = topLevelScreenFields(dynpro);
    const fieldsByName = new Map(
      screenFields.map((field) => [field.name.toUpperCase(), field]),
    );
    for (const field of screenFields) {
      const referenceFormat = { CURR: "CUKY", QUAN: "UNIT" }[field.format];
      if (!referenceFormat) continue;
      if (!field.reference) {
        fail(`${xmlName}: screen ${screen}, ${field.format} field ${field.name} has no reference field`);
      }
      const reference = fieldsByName.get(field.reference);
      if (reference && reference.format !== referenceFormat) {
        fail(
          `${xmlName}: screen ${screen}, ${field.name} references ${reference.name} ` +
          `with format ${reference.format} instead of ${referenceFormat}`,
        );
      }
    }
    for (let first = 0; first < screenFields.length; first += 1) {
      for (let second = first + 1; second < screenFields.length; second += 1) {
        const a = screenFields[first];
        const b = screenFields[second];
        const rowsOverlap = a.top <= b.bottom && b.top <= a.bottom;
        const columnsTouch = a.left <= b.right + 1 && b.left <= a.right + 1;
        if (rowsOverlap && columnsTouch) {
          fail(`${xmlName}: screen ${screen}, element ${a.name} touches or overlaps ${b.name}`);
        }
      }
    }
  }
  if (!/<TPOOL>[\s\S]*?<ID>R<\/ID>/i.test(xml)) {
    fail(`${program}: missing report title in its text pool`);
  }
  if (program !== "ZGG_GUI_CATALOG" && !plan.includes(`\`${program}\``)) {
    fail(`${program}: missing from PLAN.md`);
  }
}

const catalogPrograms = [...catalog.matchAll(/\bprogram\s*=\s*'([^']+)'/gi)]
  .map((match) => match[1].toUpperCase())
  .sort();
const samplePrograms = sampleFiles.map(programFor).sort();
if (JSON.stringify(catalogPrograms) !== JSON.stringify(samplePrograms)) {
  fail("Catalog entries do not exactly match the runnable sample reports");
}

const sampleType = catalog.match(/BEGIN OF ty_sample,([\s\S]*?)END OF ty_sample/i)?.[1] ?? "";
const catalogFields = [...sampleType.matchAll(/^\s*(\w+)\s+TYPE\b/gim)]
  .map((match) => match[1].toLowerCase());
if (JSON.stringify(catalogFields) !== JSON.stringify(["category", "program", "title"])) {
  fail("Catalog schema must contain only category, program, and title");
}

const screenFiles = files.filter((name) => /\.prog\.screen_\d{4}\.abap$/i.test(name));
for (const screenFile of screenFiles) {
  const match = screenFile.match(/^(.*)\.prog\.screen_(\d{4})\.abap$/i);
  const xmlName = `${match[1]}.prog.xml`;
  const xml = read(join(srcDir, xmlName));
  if (!xml.includes(`<SCREEN>${match[2]}</SCREEN>`)) {
    fail(`${screenFile}: screen is missing from ${xmlName}`);
  }
}

for (const file of reportFiles) {
  const xmlName = file.replace(/\.abap$/i, ".xml");
  const xml = read(join(srcDir, xmlName));
  const source = read(join(srcDir, file));
  const screens = [...xml.matchAll(/<SCREEN>(\d{4})<\/SCREEN>/g)].map((match) => match[1]);
  const screenTypes = new Map(
    [...xml.matchAll(/<item>([\s\S]*?)<\/item>/gi)].map((match) => {
      const header = match[1].match(/<HEADER>([\s\S]*?)<\/HEADER>/i)?.[1] ?? "";
      return [elementValue(header, "SCREEN"), elementValue(header, "TYPE").toUpperCase()];
    }),
  );
  const flowLogic = screenFiles
    .filter((name) => name.startsWith(file.replace(/\.abap$/i, ".screen_")))
    .map((name) => read(join(srcDir, name)))
    .join("\n");
  const dynproSource = `${source}\n${flowLogic}`;
  const referencedScreens = new Set(
    [...dynproSource.matchAll(/\bCALL\s+SCREEN\s+(\d{1,4})\b/gi)]
      .map((match) => match[1].padStart(4, "0")),
  );
  const referencedSubscreens = new Set();
  for (const match of dynproSource.matchAll(
    /\bCALL\s+SUBSCREEN\s+\w+\s+INCLUDING\s+sy-repid\s+(?:['`](\d{1,4})['`]|(\w+))/gi,
  )) {
    if (match[1]) {
      const screen = match[1].padStart(4, "0");
      referencedScreens.add(screen);
      referencedSubscreens.add(screen);
      continue;
    }
    const screenVariable = match[2].replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const assignedScreen = new RegExp(
      `\\b${screenVariable}\\b[^\\r\\n.]*['\`](\\d{1,4})['\`]`,
      "gi",
    );
    for (const assignment of dynproSource.matchAll(assignedScreen)) {
      const screen = assignment[1].padStart(4, "0");
      referencedScreens.add(screen);
      referencedSubscreens.add(screen);
    }
  }
  for (const screen of referencedScreens) {
    if (!screens.includes(screen)) {
      fail(`${file}: referenced screen ${screen} is missing from ${xmlName}`);
    }
  }
  for (const screen of referencedSubscreens) {
    if (screenTypes.get(screen) !== "I") {
      fail(`${xmlName}: subscreen ${screen} must have dynpro type I`);
    }
  }
  for (const screen of new Set(screens)) {
    const include = file.replace(/\.abap$/i, `.screen_${screen}.abap`);
    if (!files.includes(include)) fail(`${xmlName}: missing flow logic ${include}`);
  }
  if (screens.length > 0 && !/\bLEAVE\s+(?:TO\s+SCREEN\s+0|PROGRAM)\b/i.test(source)) {
    fail(`${file}: dynpro report has no explicit Back/Exit/Cancel exit path`);
  }
  if (/\bgo_events\s+TYPE\s+REF\s+TO\s+lcl_events\b/i.test(source) &&
      !/\bFREE(?::)?[^.]*\bgo_events\b/is.test(source)) {
    fail(`${file}: event receiver go_events is not released`);
  }
}

const directDatabaseDml = [
  /^\s*SELECT(?!-)\b/im,
  /^\s*INSERT\s+INTO\b/im,
  /^\s*UPDATE\s+\w+\s+SET\b/im,
  /^\s*DELETE\s+FROM\b/im,
  /^\s*COMMIT\s+WORK\b/im,
  /^\s*ROLLBACK\s+WORK\b/im,
  /^\s*OPEN\s+DATASET\b/im,
];
for (const file of reportFiles) {
  const source = read(join(srcDir, file));
  const code = source
    .replace(/^\s*\*.*$/gm, "")
    .replace(/".*$/gm, "")
    .replace(/'(?:''|[^'])*'/g, "''")
    .replace(/`[^`]*`/g, "``")
    .replace(/\|[^|]*\|/g, "||");
  for (const pattern of directDatabaseDml) {
    if (pattern.test(code)) fail(`${file}: direct persistent database operation matches ${pattern}`);
  }
}

const recorded = anomalies.split("## Recorded Anomalies")[1] ?? "";
const entries = recorded.split(/^### /m).slice(1);
const requiredAnomalyFields = [
  "Status", "Sample", "Component", "Version or commit", "Native SAP behavior",
  "open-abap behavior", "Reproduction", "Workaround", "Upstream reference",
];
for (const entry of entries) {
  const title = entry.split("\n", 1)[0];
  for (const field of requiredAnomalyFields) {
    if (!entry.includes(`- ${field}:`)) fail(`Anomaly '${title}' is missing '${field}'`);
  }
}
if (entries.length === 0) fail("ANORMALIES.md has no recorded anomalies");

for (const requiredText of [
  "Update this file in the same change",
  "ANORMALIES.md",
  "7643d3b98058b1c47509e1a42af3187b7f6fbff7",
]) {
  if (!plan.includes(requiredText)) fail(`PLAN.md is missing required policy text: ${requiredText}`);
}

console.log(
  `Repository verification passed: ${sampleFiles.length} samples, ` +
  `${catalogPrograms.length} catalog rows, ${screenFiles.length} screen includes, ` +
  `${entries.length} anomaly records.`,
);
