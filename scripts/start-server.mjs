import express from "express";
import path from "node:path";
import {pathToFileURL} from "node:url";

// Serves the transpiled transactions through the open-abap-gui HTTP handler.
// Run `npm start`, which converts and transpiles first, then open the printed
// URL; `/transaction?tcode=ZGG_GUI_CATALOG` starts a transaction directly.

const outputRoot = path.resolve(process.env.GG_GUI_OUTPUT ?? "output");
await import(pathToFileURL(path.join(outputRoot, "init.mjs")).href);
const {cl_express_icf_shim} = await import(
  pathToFileURL(path.join(outputRoot, "cl_express_icf_shim.clas.mjs")).href);

const MAX_BODY_BYTES = 1024 * 1024;

const app = express();
app.disable("x-powered-by");
app.set("etag", false);
app.use(express.raw({type: "*/*", limit: MAX_BODY_BYTES}));

app.all("*", async (request, response, next) => {
  try {
    await cl_express_icf_shim.run({
      req: request,
      res: response,
      class: "ZCL_GG_HTTP_HANDLER",
    });
  } catch (error) {
    next(error);
  }
});

app.use((error, request, response, next) => {
  if (response.headersSent) {
    next(error);
    return;
  }
  console.error(error);
  response.status(500).type("application/json").send({
    valid: false,
    error: error instanceof Error ? error.message : String(error),
  });
});

const host = process.env.GG_GUI_HOST ?? "127.0.0.1";
const port = Number(process.env.GG_GUI_PORT ?? 8080);
const server = app.listen(port, host, () => {
  console.log(`gg-gui transactions served at http://${host}:${server.address().port}`);
});

let shuttingDown = false;
for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, async () => {
    if (shuttingDown) return;
    shuttingDown = true;
    server.close();
    await globalThis.abap.Classes.ZCL_GG_HTTP_HANDLER.shutdown();
    process.exit(0);
  });
}
