import type { FlomoArchive, FlomoNote, Media } from "./archive";

export type Mode = "day" | "card";

export const noteTypes = { day: "daily", card: "card_note" } as const;

export interface ImportOptions {
  start: string;
  end: string;
  mode: Mode;
  folder: string;
}

export interface ImportRecord {
  notes: string[];
  attachments: Record<string, string>;
  completed: boolean;
}

export interface PlannedNote {
  path: string;
  created: string;
  notes: FlomoNote[];
}

export interface ImportPlan {
  key: string;
  options: ImportOptions;
  files: PlannedNote[];
  attachmentFolder: string;
  attachmentPaths: Map<string, string>;
  noteCount: number;
  missing: number;
  renamed: number;
  record?: ImportRecord;
}

export const joinPath = (...parts: string[]) => parts.filter(Boolean).join("/");
export const basename = (path: string) => path.slice(path.lastIndexOf("/") + 1);
export const parentPath = (path: string) => path.includes("/") ? path.slice(0, path.lastIndexOf("/")) : "";
export const pathKey = (path: string) => path.normalize("NFC").toLowerCase();

const windowsDevice = /^(?:con|prn|aux|nul|(?:com|lpt)[0-9¹²³])(?:\.|$)/i;
const pathCharacters = /[<>:"\\|?*\x00-\x1f]/;
const segmenter = new Intl.Segmenter("zh", { granularity: "grapheme" });

export function folderPath(raw: string): string | undefined {
  const value = raw.trim().normalize("NFC").replace(/\/+$/, "");
  if (!value) return raw.trim().startsWith("//") ? undefined : "";
  const parts = value.split("/");
  if (parts.some((part) => !part || part.startsWith(".") || /[ .]$/.test(part)
    || windowsDevice.test(part) || pathCharacters.test(part))) return;
  return value;
}

export function attachmentDirectory(preference: string, noteFolder: string): string {
  if (preference === "./") return noteFolder;
  if (preference.startsWith("./")) {
    const child = folderPath(preference.slice(2));
    if (child === undefined) throw new Error("Obsidian 的附件子目录路径无效，请在「文件与链接」中检查。");
    return joinPath(noteFolder, child);
  }
  const folder = folderPath(preference);
  if (folder === undefined) throw new Error("Obsidian 的附件目录路径无效，请在「文件与链接」中检查。");
  return folder;
}

export function selectNotes(notes: readonly FlomoNote[], start: string, end: string): FlomoNote[] {
  return notes.filter(({ timestamp }) => {
    const date = timestamp.slice(0, 10);
    return start <= date && date <= end;
  });
}

export function noteTitle(note: FlomoNote): string {
  const line = note.content.split("\n", 1)[0].replace(/#(\S+)/g, "$1").trim();
  if (!line) return `无标题 ${note.timestamp.replace(/:/g, "")}`;
  const characters = [...segmenter.segment(line)].map(({ segment }) => segment);
  return characters.length > 20 ? characters.slice(0, 20).join("") + "…" : line;
}

function safeName(name: string): string {
  const clean = name.normalize("NFC")
    .replace(/[<>:"/\\|?*#\[\]^\x00-\x1f]/g, "-").trim()
    .replace(/^\.+/, "").replace(/[ .]+$/, "");
  if (!clean) return "无标题";
  return windowsDevice.test(clean) ? `_${clean}` : clean;
}

function reserve(folder: string, name: string, extension: string, paths: Set<string>): string {
  let path = joinPath(folder, `${name}${extension}`);
  let n = 2;
  while (paths.has(pathKey(path))) {
    path = joinPath(folder, `${name}-${n++}${extension}`);
  }
  paths.add(pathKey(path));
  return path;
}

export async function batchKey(archive: FlomoArchive, notes: readonly FlomoNote[], mode: Mode, folder: string): Promise<string> {
  const identity = notes.map((note) => [
    note.timestamp, note.content, note.media.map((asset) => [
      asset.kind, asset.transcript, asset.entry ? [asset.entry, ...archive.signature(asset.entry)] : asset.reference,
    ]),
  ]);
  return sha256(new TextEncoder().encode(JSON.stringify([mode, pathKey(folder), identity])));
}

export async function sha256(bytes: Uint8Array<ArrayBuffer>): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

export function buildPlan(
  key: string, notes: FlomoNote[], options: ImportOptions, preference: string,
  occupied: Iterable<string>, record?: ImportRecord,
): ImportPlan {
  const folder = attachmentDirectory(preference, options.folder);
  const used = new Set(Array.from(occupied, pathKey));
  const groups = new Map<string | FlomoNote, FlomoNote[]>();
  for (const note of notes) {
    const group = options.mode === "day" ? note.timestamp.slice(0, 10) : note;
    const items = groups.get(group);
    if (items) items.push(note);
    else groups.set(group, [note]);
  }

  let renamed = 0;
  const files = Array.from(groups, ([group, items], index) => {
    const base = typeof group === "string" ? group : safeName(noteTitle(items[0]));
    const path = record?.notes[index] ?? reserve(options.folder, base, ".md", used);
    if (basename(path) !== `${base}.md`) renamed++;
    return { path, created: typeof group === "string" ? group : items[0].timestamp, notes: items };
  });

  let missing = 0;
  const attachmentPaths = new Map<string, string>();
  for (const note of notes) {
    for (const media of note.media) {
      if (!media.entry) {
        missing++;
        continue;
      }
      if (attachmentPaths.has(media.entry)) continue;
      const original = basename(media.entry);
      const dot = original.lastIndexOf(".");
      const stem = safeName(original.slice(0, dot));
      const extension = original.slice(dot);
      const path = record?.attachments[media.entry] ?? reserve(folder, stem, extension, used);
      if (basename(path) !== `${stem}${extension}`) renamed++;
      attachmentPaths.set(media.entry, path);
    }
  }
  const recordedAttachment = attachmentPaths.values().next().value;
  return {
    key, options, files, attachmentPaths, noteCount: notes.length, renamed, missing, record,
    attachmentFolder: recordedAttachment === undefined ? folder : parentPath(recordedAttachment),
  };
}

function embed(notePath: string, destination: string): string {
  const from = parentPath(notePath).split("/").filter(Boolean);
  const to = destination.split("/");
  while (from.length && from[0] === to[0]) {
    from.shift();
    to.shift();
  }
  const encode = (part: string) => encodeURIComponent(part).replace(/[!'()*]/g, (value) => `%${value.charCodeAt(0).toString(16)}`);
  const path = [...from.map(() => ".."), ...to.map(encode)].join("/");
  // Without an explicit relative prefix Obsidian may choose a same-named file elsewhere.
  return `![](${from.length ? "" : "./"}${path})`;
}

function renderMedia(file: PlannedNote, media: Media, paths: ReadonlyMap<string, string>): string | undefined {
  const path = media.entry ? paths.get(media.entry) : undefined;
  const link = path ? embed(file.path, path) : undefined;
  if (media.kind === "image") return link;
  if (!link && !media.transcript) return;
  const body = [link, media.transcript].filter(Boolean).join("\n");
  return `> [!tip]+ 语音\n${body.split("\n").map((line) => line ? `> ${line}` : ">").join("\n")}`;
}

export function renderMarkdown(file: PlannedNote, plan: ImportPlan): string {
  const cards = file.notes.map((note) => [
    plan.options.mode === "day" ? `# ${noteTitle(note)}` : "",
    note.content,
    ...note.media.map((asset) => renderMedia(file, asset, plan.attachmentPaths)),
  ].filter(Boolean).join("\n\n"));
  return `---\ncreated: ${file.created}\ntype: ${noteTypes[plan.options.mode]}\n---\n\n${cards.join("\n\n---\n\n")}\n`;
}

export function sameDestinations(left: ImportPlan, right: ImportPlan): boolean {
  return left.files.length === right.files.length
    && left.files.every(({ path }, index) => path === right.files[index].path)
    && left.attachmentPaths.size === right.attachmentPaths.size
    && [...left.attachmentPaths].every(([entry, path]) => right.attachmentPaths.get(entry) === path);
}
