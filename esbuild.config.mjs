import { readFile } from "node:fs/promises"
import { build } from "esbuild"

const bundledPackages = ["@zip.js/zip.js", "parse5", "entities"]
const licenses = await Promise.all(bundledPackages.map(async (name) => {
  const license = await readFile(new URL(`./node_modules/${name}/LICENSE`, import.meta.url), "utf8")
  return `${name}\n${license.trim()}`
}))

await build({
  entryPoints: ["src/main.ts"],
  outfile: "main.js",
  bundle: true,
  external: ["obsidian"],
  platform: "browser",
  format: "cjs",
  target: "es2022",
  minify: true,
  banner: { js: `/*\n${licenses.join("\n\n")}\n*/` },
  logLevel: "info",
})
