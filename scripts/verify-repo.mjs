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

const reportFiles = files.filter((name) => /^zgg_gui_.+\.prog\.abap$/i.test(name));
const sampleFiles = reportFiles.filter((name) => name !== "zgg_gui_catalog.prog.abap");
const programFor = (name) => name.replace(/\.prog\.abap$/i, "").toUpperCase();
const plan = read(join(root, "PLAN.md"));
const anomalies = read(join(root, "ANORMALIES.md"));
const abaplintConfig = read(join(root, "abaplint.jsonc"));
const catalog = read(join(srcDir, "zgg_gui_catalog.prog.abap"));

if (!/"version"\s*:\s*"v750"/.test(abaplintConfig)) {
  fail("abaplint syntax version must remain v750 to match the declared minimum release");
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
