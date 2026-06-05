// Minimal static file server for the test suite.
//
// Multi-threaded ffmpeg-core needs SharedArrayBuffer, which the browser only
// exposes when the document is crossOriginIsolated. That requires the
// Cross-Origin-Opener-Policy and Cross-Origin-Embedder-Policy *HTTP response
// headers* (the equivalent <meta http-equiv> tags are ignored by browsers).
//
// `http-server` cannot set arbitrary headers, so we serve the repo root here.
const http = require("http");
const fs = require("fs");
const path = require("path");
const { URL } = require("url");

const PORT = Number(process.env.PORT) || 3000;
const ROOT = path.resolve(__dirname, "..");

const MIME = {
  ".html": "text/html",
  ".js": "text/javascript",
  ".mjs": "text/javascript",
  ".css": "text/css",
  ".json": "application/json",
  ".wasm": "application/wasm",
  ".map": "application/json",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".svg": "image/svg+xml",
  ".woff2": "font/woff2",
};

const server = http.createServer((req, res) => {
  res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
  res.setHeader("Cross-Origin-Embedder-Policy", "require-corp");
  res.setHeader("Cross-Origin-Resource-Policy", "cross-origin");
  res.setHeader("Origin-Agent-Cluster", "?1");
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Cache-Control", "no-store");

  const pathname = decodeURIComponent(new URL(req.url, "http://localhost").pathname);
  const filePath = path.join(ROOT, pathname);

  // Prevent path traversal outside the repo root.
  if (!filePath.startsWith(ROOT)) {
    res.writeHead(403).end("Forbidden");
    return;
  }

  fs.stat(filePath, (err, stat) => {
    if (err || !stat.isFile()) {
      res.writeHead(404).end("Not found");
      return;
    }
    res.setHeader("Content-Type", MIME[path.extname(filePath)] || "application/octet-stream");
    fs.createReadStream(filePath).pipe(res);
  });
});

server.listen(PORT, () => {
  console.log(`Test server (crossOriginIsolated) listening on http://localhost:${PORT}`);
});
