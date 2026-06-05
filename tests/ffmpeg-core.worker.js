// Hosts ffmpeg-core off the main browser thread.
//
// As of FFmpeg 8.0 the CLI runs on a thread-based scheduler, so exec() blocks
// on `Atomics.wait`. That is illegal on a page's main thread but perfectly fine
// inside a Web Worker, which is where production (@ffmpeg/ffmpeg) runs the core
// too. This worker exposes a tiny RPC the test driver talks to.

let core;

const post = (msg, transfer) => self.postMessage(msg, transfer || []);

const load = async (coreURL) => {
  // Classic worker: pull the UMD core in, which defines self.createFFmpegCore.
  importScripts(coreURL);

  const wasmURL = coreURL.replace(/\.js$/, ".wasm");
  const workerURL = coreURL.replace(/\.js$/, ".worker.js");

  core = await self.createFFmpegCore({
    // Encode wasmURL/workerURL in the URL hash so the multi-threaded core can
    // locate its sibling .wasm and pthread worker (same hack as the library's
    // worker.ts).
    mainScriptUrlOrBlob: `${coreURL}#${btoa(
      JSON.stringify({ wasmURL, workerURL })
    )}`,
  });

  core.setLogger((data) => post({ type: "log", data }));
  core.setProgress((data) => post({ type: "progress", data }));
};

self.onmessage = async ({ data: { id, type, payload } }) => {
  try {
    let data;
    switch (type) {
      case "load":
        await load(payload.coreURL);
        data = true;
        break;
      case "writeFile":
        core.FS.writeFile(payload.name, payload.data);
        data = true;
        break;
      case "readFile":
        data = core.FS.readFile(payload.name);
        break;
      case "unlink":
        core.FS.unlink(payload.name);
        data = true;
        break;
      case "reset":
        core.reset();
        data = true;
        break;
      case "setTimeout":
        core.setTimeout(payload.ms);
        data = true;
        break;
      case "exec":
        data = core.exec(...payload.args);
        break;
      case "get":
        data = core[payload.prop];
        break;
      case "set":
        core[payload.prop] = payload.value;
        data = true;
        break;
      default:
        throw new Error(`unknown message type: ${type}`);
    }
    const transfer = data instanceof Uint8Array ? [data.buffer] : [];
    post({ id, data }, transfer);
  } catch (e) {
    post({ id, error: e.toString() });
  }
};
