import { App, TFolder } from "obsidian";
import { BlobWriter, TextReader, Uint8ArrayReader, ZipWriter } from "@zip.js/zip.js";
import type { FlomoArchive } from "./archive";
import {
  attachmentDirectory, batchKey, buildPlan, joinPath, parentPath, renderMarkdown, selectNotes,
  type ImportOptions, type ImportPlan, type ImportRecord,
} from "./conversion";

export interface ImportResult {
  files: string[];
  assets: string[];
  failures: string[];
}

export type Progress = (done: number, total: number) => void;
export type SaveRecord = (key: string, record: ImportRecord) => Promise<void>;

function message(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

export class Importer {
  constructor(
    private readonly app: App,
    private readonly records: Record<string, ImportRecord>,
    private readonly saveRecord: SaveRecord,
  ) {}

  private async attachmentPreference(): Promise<string> {
    const { vault } = this.app;
    const path = joinPath(vault.configDir, "app.json");
    if (!await vault.adapter.exists(path)) return "/";
    const config = JSON.parse(await vault.adapter.read(path)) as { attachmentFolderPath?: unknown };
    if (typeof config.attachmentFolderPath === "string") return config.attachmentFolderPath;
    return "/";
  }

  async prepare(archive: FlomoArchive, options: ImportOptions): Promise<ImportPlan> {
    const notes = selectNotes(archive.notes, options.start, options.end);
    const [key, preference] = await Promise.all([
      batchKey(archive, notes, options.mode, options.folder),
      this.attachmentPreference(),
    ]);
    const { vault } = this.app;
    const protectedFolder = vault.configDir.toLowerCase();
    const plan = buildPlan(
      key, notes, options, preference, vault.getAllLoadedFiles().map((file) => file.path), this.records[key],
    );
    for (const folder of [options.folder, plan.attachmentFolder]) {
      if (folder.toLowerCase() === protectedFolder || folder.toLowerCase().startsWith(protectedFolder + "/")) {
        throw new Error("导入目录位于 Obsidian 的配置目录中。请选择仓库里的笔记或附件文件夹。");
      }
    }
    return plan;
  }

  async write(archive: FlomoArchive, plan: ImportPlan, progress: Progress): Promise<ImportResult> {
    const existing = plan.record;
    if (existing?.completed) {
      return { files: existing.notes, assets: Object.values(existing.attachments), failures: [] };
    }
    if (plan.attachmentPaths.size) {
      const currentFolder = attachmentDirectory(await this.attachmentPreference(), plan.options.folder);
      if (currentFolder !== plan.attachmentFolder) {
        throw new Error("当前附件位置与待继续的导入不一致。请在「文件与链接」中恢复该批次的附件位置。");
      }
    }
    const record: ImportRecord = existing ?? {
      notes: plan.files.map(({ path }) => path),
      attachments: Object.fromEntries(plan.attachmentPaths),
      completed: false,
    };
    await this.saveRecord(plan.key, record);
    plan.record = record;

    const { vault } = this.app;
    const { adapter } = vault;
    const result: ImportResult = { files: [], assets: [], failures: [] };

    const total = plan.files.length + plan.attachmentPaths.size;
    let finished = 0;
    const failedEntries = new Set<string>();
    for (const [entry, destination] of plan.attachmentPaths) {
      try {
        const bytes = await archive.read(entry);
        if (await adapter.exists(destination)) {
          if (!existing || !equalBytes(bytes, new Uint8Array(await adapter.readBinary(destination)))) {
            throw new Error("目标已存在，已保留原文件。");
          }
        } else {
          // Obsidian resolves a relative attachment path against an existing note.
          // At this point the note is still being imported, so use the precomputed destination.
          await this.ensureFolder(parentPath(destination));
          await vault.createBinary(destination, bytes.buffer);
        }
        result.assets.push(destination);
      } catch (error) {
        failedEntries.add(entry);
        result.failures.push(`${destination}：${message(error)}`);
      }
      progress(++finished, total);
    }

    for (const file of plan.files) {
      try {
        if (file.notes.some((note) => note.media.some(({ entry }) => entry && failedEntries.has(entry)))) {
          throw new Error("有附件尚未写入。");
        }
        const markdown = renderMarkdown(file, plan);
        if (await adapter.exists(file.path)) {
          const current = existing && await adapter.read(file.path);
          // An interrupted batch may already have written this note using the old frontmatter.
          const legacy = markdown.replace(/^(---\ncreated: [^\n]+\n)type: (?:daily|card_note)\n/, "$1noteType: CardNote\n");
          if (current !== markdown && current !== legacy) {
            throw new Error("目标已存在，已保留原文件。");
          }
        } else {
          await this.ensureFolder(parentPath(file.path));
          await vault.create(file.path, markdown);
        }
        result.files.push(file.path);
      } catch (error) {
        result.failures.push(`${file.path}：${message(error)}`);
      }
      progress(++finished, total);
    }
    if (!result.failures.length) {
      const completed = { ...record, completed: true };
      await this.saveRecord(plan.key, completed);
      plan.record = completed;
    }
    return result;
  }

  private async ensureFolder(path: string): Promise<void> {
    if (!path) return;
    const { vault } = this.app;
    if (vault.getAbstractFileByPath(path) instanceof TFolder) return;
    await this.ensureFolder(parentPath(path));
    try {
      await vault.createFolder(path);
    } catch (error) {
      if (!(vault.getAbstractFileByPath(path) instanceof TFolder)) throw error;
    }
  }
}

function equalBytes(left: Uint8Array, right: Uint8Array): boolean {
  return left.length === right.length && left.every((value, index) => value === right[index]);
}

export async function exportZip(
  archive: FlomoArchive, plan: ImportPlan, progress: Progress, output?: WritableStream,
): Promise<Blob | undefined> {
  const writer = new ZipWriter<Blob | undefined>(output ?? new BlobWriter("application/zip"), { useWebWorkers: false, level: 0 });
  const total = plan.files.length + plan.attachmentPaths.size;
  let done = 0;
  try {
    for (const { path, ...file } of plan.files) {
      await writer.add(path, new TextReader(renderMarkdown({ path, ...file }, plan)));
      progress(++done, total);
    }
    for (const [entry, path] of plan.attachmentPaths) {
      await writer.add(path, new Uint8ArrayReader(await archive.read(entry)));
      progress(++done, total);
    }
    return await writer.close();
  } catch (error) {
    if (!output) await writer.close().catch(() => {});
    throw error;
  }
}
