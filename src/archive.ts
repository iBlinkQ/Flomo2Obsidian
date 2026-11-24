import { BlobReader, Uint8ArrayWriter, ZipReader, type FileEntry } from "@zip.js/zip.js";

export interface Media {
  reference: string;
  entry?: string;
  kind: "image" | "audio";
  transcript?: string;
}

export interface FlomoNote {
  timestamp: string;
  content: string;
  media: Media[];
}

const zipOptions = { useWebWorkers: false };
const mediaExt = /\.(?:png|jpe?g|gif|webp|bmp|svg|avif|heic|m4a|mp3|aac|ogg|opus|wav|flac|webm|mp4)$/i;

function archivePath(raw: string): string | undefined {
  const path = raw.replace(/\\/g, "/");
  if (/^(?:\/|[a-z][a-z\d+.-]*:)/i.test(path) || path.includes("\0")) return;
  const segments: string[] = [];
  for (const part of path.split("/")) {
    if (part === "..") {
      if (!segments.length) return;
      segments.pop();
    } else if (part && part !== ".") {
      segments.push(part);
    }
  }
  return segments.join("/") || undefined;
}

function resolveReference(source: string, ref: string, entries: ReadonlySet<string>): string | undefined {
  if (/^(?:\/|[a-z][a-z\d+.-]*:)/i.test(ref.replace(/\\/g, "/"))) return;
  const base = source.split("/").slice(0, -1).join("/");
  const pathPart = ref.split(/[?#]/, 1)[0];
  let decoded = pathPart;
  try {
    decoded = decodeURIComponent(pathPart);
  } catch {
    // Old exports can contain literal percent signs in filenames.
  }
  for (const candidate of new Set([decoded, ref, pathPart])) {
    if (/^(?:\/|[a-z][a-z\d+.-]*:)/i.test(candidate.replace(/\\/g, "/"))) continue;
    for (const path of [archivePath(base ? `${base}/${candidate}` : candidate), archivePath(candidate)]) {
      if (path && entries.has(path) && mediaExt.test(path)) return path;
    }
  }
}

function inlineText(node: Node): string {
  if (node.nodeType === 3) return node.textContent ?? "";
  if (node.nodeType === 1) {
    const tag = (node as Element).tagName.toLowerCase();
    if (tag === "br") return "\n";
    if (["script", "style", "template", "iframe", "img", "audio", "video"].includes(tag)) return "";
  }
  return Array.from(node.childNodes).map(inlineText).join("");
}

function cleanText(text: string): string {
  return text.split("\n").map((line) => line.replace(/[\t\u00a0\r ]+/g, " ").trim()).join("\n").trim();
}

function listLines(list: Element, level = 0): string[] {
  return Array.from(list.children).filter((item) => item.tagName.toLowerCase() === "li").flatMap((item, index) => {
    const children = Array.from(item.childNodes);
    const isList = (node: Node) => node.nodeType === 1 && /^(OL|UL)$/i.test((node as Element).tagName);
    const text = cleanText(children.filter((node) => !isList(node)).map(inlineText).join(""));
    const indent = "    ".repeat(level);
    const marker = list.tagName.toLowerCase() === "ol" ? `${index + 1}.` : "-";
    return [
      ...(text ? [`${indent}${marker} ${text.replace(/\n/g, `\n${indent}    `)}`] : []),
      ...children.filter(isList).flatMap((child) => listLines(child as Element, level + 1)),
    ];
  });
}

function extractContent(content: Element): string {
  return Array.from(content.childNodes).flatMap((node) => {
    if (node.nodeType === 1 && /^(OL|UL)$/i.test((node as Element).tagName)) return listLines(node as Element);
    const text = cleanText(inlineText(node));
    return text ? [text] : [];
  }).join("\n");
}

function readTimestamp(raw: string): string | undefined {
  const value = raw.trim().replace("T", " ");
  if (!/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/.test(value)) return;
  const date = new Date(value.replace(" ", "T") + "Z");
  if (Number.isFinite(date.getTime()) && date.toISOString().slice(0, 19).replace("T", " ") === value) return value;
}

export function parseFlomoHtml(doc: Document, html: string, source: string, entries: ReadonlySet<string>) {
  // Template content is inert. Archive HTML is never mounted into the app.
  const template = doc.createElement("template");
  template.innerHTML = html;
  const notes: FlomoNote[] = [];
  let skipped = 0;
  for (const memo of template.content.querySelectorAll("div.memo")) {
    const content = memo.querySelector("div.content");
    const timestamp = readTimestamp(memo.querySelector("div.time")?.textContent ?? "");
    if (!content || !timestamp) {
      skipped++;
      continue;
    }
    const media: Media[] = [];
    for (const player of memo.querySelectorAll("div.audio-player")) {
      const ref = player.querySelector("audio[src], audio source[src]")?.getAttribute("src")?.trim();
      if (!ref) continue;
      media.push({
        reference: ref, entry: resolveReference(source, ref, entries), kind: "audio",
        transcript: cleanText(inlineText(player.querySelector("div.audio-player__content") ?? doc.createTextNode(""))),
      });
    }
    for (const image of memo.querySelectorAll("div.files img[src]")) {
      const ref = image.getAttribute("src")?.trim();
      if (ref) media.push({ reference: ref, entry: resolveReference(source, ref, entries), kind: "image" });
    }
    notes.push({ timestamp, content: extractContent(content), media });
  }
  return { notes, skipped };
}

export class FlomoArchive {
  private readonly reader: ZipReader<Blob>;
  private readonly entries = new Map<string, FileEntry>();
  readonly notes: FlomoNote[] = [];
  skipped = 0;

  private constructor(file: Blob) {
    this.reader = new ZipReader(new BlobReader(file), zipOptions);
  }

  static async open(file: Blob, doc: Document): Promise<FlomoArchive> {
    const archive = new FlomoArchive(file);
    try {
      const entries = await archive.reader.getEntries();
      for (const entry of entries) {
        const path = archivePath(entry.filename);
        if (!entry.directory && path && !path.startsWith("__MACOSX/")) {
          if (archive.entries.has(path)) throw new Error(`ZIP 中存在重复路径：${path}`);
          archive.entries.set(path, entry);
        }
      }
      const names = new Set(archive.entries.keys());
      for (const path of names) {
        if (!/\.html?$/i.test(path)) continue;
        const html = new TextDecoder("utf-8", { fatal: true, ignoreBOM: false }).decode(await archive.read(path));
        const { notes, skipped } = parseFlomoHtml(doc, html, path, names);
        archive.notes.push(...notes);
        archive.skipped += skipped;
      }
      if (!archive.notes.length) throw new Error("ZIP 中未识别到有效的 Flomo 笔记，请检查导出文件。");
      archive.notes.sort((left, right) => left.timestamp.localeCompare(right.timestamp));
      return archive;
    } catch (error) {
      await archive.close();
      throw error;
    }
  }

  async read(path: string): Promise<Uint8Array<ArrayBuffer>> {
    const entry = this.entries.get(path);
    if (!entry) throw new Error(`找不到附件：${path}`);
    return entry.getData(new Uint8ArrayWriter(), { checkSignature: true, ...zipOptions });
  }

  signature(path: string): [number | null, number] {
    const entry = this.entries.get(path);
    if (!entry) throw new Error(`找不到附件：${path}`);
    return [entry.signature ?? null, entry.uncompressedSize];
  }

  async close(): Promise<void> {
    await this.reader.close();
  }
}

export function mediaMime(path: string): string {
  const ext = path.split(".").at(-1)?.toLowerCase() ?? "";
  const types: Record<string, string> = {
    png: "image/png", jpg: "image/jpeg", jpeg: "image/jpeg", gif: "image/gif", webp: "image/webp",
    svg: "image/svg+xml", bmp: "image/bmp", avif: "image/avif", heic: "image/heic",
    m4a: "audio/mp4", mp3: "audio/mpeg", mp4: "audio/mp4", wav: "audio/wav",
    flac: "audio/flac", aac: "audio/aac", ogg: "audio/ogg", opus: "audio/ogg", webm: "audio/webm",
  };
  return types[ext] ?? "application/octet-stream";
}
