import { readFile } from "node:fs/promises"
import { build } from "esbuild"

const zipLicense = await readFile(new URL("./node_modules/@zip.js/zip.js/LICENSE", import.meta.url), "utf8")

await build({
  entryPoints: ["src/main.ts"],
  outfile: "main.js",
  bundle: true,
  external: ["obsidian"],
  platform: "browser",
  format: "cjs",
  target: "es2022",
  minify: true,
  banner: { js: `/*\n${zipLicense.trim()}\n*/` },
  logLevel: "info",
})
