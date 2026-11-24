import { App, FuzzySuggestModal, Modal, Notice, TFile, TFolder, setIcon } from "obsidian";
import { FlomoArchive, mediaMime, type Media } from "./archive";
import {
  basename, folderPath, noteTitle, noteTypes, renderMarkdown, sameDestinations, selectNotes,
  type ImportOptions, type ImportPlan, type Mode, type PlannedNote,
} from "./conversion";
import { exportZip, Importer, type ImportResult, type Progress } from "./importer";

type Stage = "source" | "options" | "preview" | "result";
type SavePickerWindow = Window & {
  showSaveFilePicker?: (options: {
    suggestedName: string;
    types: { description: string; accept: Record<string, string[]> }[];
  }) => Promise<FileSystemFileHandle>;
};
const exportGuide = "https://help.flomoapp.com/basic/storage.html";
const folderLabel = (path: string) => path || "仓库根目录";

export class FolderPicker extends FuzzySuggestModal<string> {
  constructor(app: App, private readonly select: (path: string) => void) {
    super(app);
    this.setPlaceholder("搜索当前仓库的文件夹名称或路径");
  }

  getItems(): string[] {
    const configDir = this.app.vault.configDir;
    return ["", ...this.app.vault.getAllLoadedFiles()
      .filter((file) => file instanceof TFolder && file.path !== "/" && file.path !== configDir && !file.path.startsWith(configDir + "/"))
      .map(({ path }) => path)
      .sort((a, b) => a.localeCompare(b, "zh"))];
  }

  getItemText(path: string): string {
    return folderLabel(path);
  }

  onChooseItem(path: string): void {
    this.select(path);
  }
}

export class ImportModal extends Modal {
  private archive?: FlomoArchive;
  private source = "";
  private options: ImportOptions;
  private stage: Stage = "source";
  private operation = "";
  private loading = false;
  private closed = false;
  private error = "";
  private plan?: ImportPlan;
  private result?: ImportResult;
  private selected = 0;
  private raw = false;
  private readonly mediaUrls = new Set<string>();

  constructor(
    app: App,
    private readonly importer: Importer,
    defaults: Pick<ImportOptions, "mode" | "folder">,
    private readonly didClose: () => void,
  ) {
    super(app);
    this.options = { ...defaults, start: "", end: "" };
  }

  onOpen(): void {
    this.modalEl.addClass("flomo-import-modal");
    this.setTitle("导入 Flomo 笔记");
    this.render();
  }

  close(): void {
    if (!this.operation) super.close();
  }

  onClose(): void {
    this.closed = true;
    this.revokeMedia();
    void this.archive?.close().catch(() => {});
    this.contentEl.empty();
    this.didClose();
  }

  private render(): void {
    if (this.closed) return;
    this.revokeMedia();
    const { contentEl } = this;
    contentEl.empty();
    contentEl.createDiv({ cls: "flomo-vault-name", text: `当前仓库 · ${this.app.vault.getName()}` });
    const steps = contentEl.createEl("ol", { cls: "flomo-step-list", attr: { "aria-label": "导入步骤" } });
    const current = { source: 0, options: 1, preview: 2, result: 2 }[this.stage];
    ["选文件", "导入设置", "预览结果"].forEach((label, index) => {
      const step = steps.createEl("li");
      step.createSpan({ cls: "flomo-step-number", text: String(index + 1) });
      step.createSpan({ text: label });
      if (index === current) step.setAttribute("aria-current", "step");
      else if (index < current) step.addClass("flomo-step-done");
    });
    if (this.error) contentEl.createDiv({ cls: "flomo-error", text: this.error, attr: { role: "alert" } });
    if (this.operation) {
      const progress = contentEl.createDiv({ cls: "flomo-progress", attr: { role: "status" } });
      progress.createEl("h3", { text: this.operation });
      progress.createEl("progress", { attr: { max: "1", value: "0", "aria-label": this.operation } });
      progress.createEl("p", { cls: "flomo-progress-detail" });
      return;
    }
    switch (this.stage) {
      case "source": this.renderSource(); break;
      case "options": this.renderOptions(); break;
      case "preview": this.renderPreview(); break;
      case "result": this.renderResult();
    }
  }

  private setStage(stage: Stage): void {
    this.stage = stage;
    this.error = "";
    this.render();
    this.contentEl.querySelector<HTMLElement>(".flomo-focus-start")?.focus();
  }

  private report(error: unknown): void {
    this.error = error instanceof Error ? error.message : String(error);
    this.render();
  }

  private button(container: HTMLElement, text: string, action: () => void, primary = false): HTMLButtonElement {
    const button = container.createEl("button", { text, cls: primary ? "mod-cta" : "", attr: { type: "button" } });
    button.addEventListener("click", action);
    return button;
  }

  private footer(text = ""): HTMLElement {
    const footer = this.contentEl.createDiv({ cls: "flomo-footer" });
    if (text) footer.createSpan({ cls: "flomo-secondary", text });
    return footer.createDiv({ cls: "flomo-actions" });
  }

  private renderSource(): void {
    const drop = this.contentEl.createDiv({ cls: "flomo-drop" });
    const icon = drop.createSpan({ cls: "flomo-drop-icon" });
    setIcon(icon, "file-archive");
    drop.createEl("h3", { text: "选择 Flomo 导出的 ZIP" });
    drop.createEl("p", { cls: "flomo-secondary", text: this.loading ? "正在读取 ZIP…" : "可直接把 ZIP 拖到这里。" });
    const input = drop.createEl("input", { attr: { type: "file", accept: ".zip,application/zip", hidden: "" } });
    const choose = this.button(drop, "选择 ZIP…", () => input.click(), true);
    choose.addClass("flomo-focus-start");
    choose.disabled = this.loading;
    const help = drop.createEl("a", {
      text: "如何导出 ZIP？", cls: "flomo-help",
      attr: { href: exportGuide, target: "_blank", rel: "noopener noreferrer" },
    });
    help.classList.add("external-link");

    input.addEventListener("change", () => {
      const file = input.files?.[0];
      if (file) void this.load(file);
    });
    drop.addEventListener("dragover", (event) => {
      event.preventDefault();
      drop.addClass("is-dragging");
    });
    drop.addEventListener("dragleave", () => drop.removeClass("is-dragging"));
    drop.addEventListener("drop", (event) => {
      event.preventDefault();
      drop.removeClass("is-dragging");
      const file = event.dataTransfer?.files[0];
      if (file) void this.load(file);
    });
    const actions = this.footer("导入在本地处理");
    if (this.archive) {
      const previous = this.button(actions, `继续设置 · ${this.source}`, () => this.setStage("options"));
      previous.disabled = this.loading;
    }
  }

  private async load(file: File): Promise<void> {
    if (this.loading || this.operation) return;
    if (!/\.zip$/i.test(file.name)) {
      this.report(new Error("请选择 Flomo 导出的 ZIP 文件。"));
      return;
    }
    const previous = this.archive;
    this.loading = true;
    this.error = "";
    this.render();
    try {
      const archive = await FlomoArchive.open(file, this.contentEl.ownerDocument);
      if (this.closed) {
        await archive.close();
        return;
      }
      await previous?.close();
      this.archive = archive;
      this.source = file.name;
      this.options.start = archive.notes[0].timestamp.slice(0, 10);
      this.options.end = archive.notes.at(-1)!.timestamp.slice(0, 10);
      this.selected = 0;
      this.setStage("options");
    } catch (error) {
      this.error = `读取 ZIP 失败：${error instanceof Error ? error.message : String(error)}`;
    } finally {
      this.loading = false;
      if (this.stage === "source") this.render();
    }
  }

  private renderOptions(): void {
    const archive = this.archive!;
    const start = archive.notes[0].timestamp.slice(0, 10);
    const end = archive.notes.at(-1)!.timestamp.slice(0, 10);
    const summary = this.contentEl.createDiv({ cls: "flomo-source-summary" });
    summary.createEl("strong", { text: this.source });
    summary.createDiv({ cls: "flomo-secondary", text: `${archive.notes.length} 条笔记 · ${start} 至 ${end}` });
    if (archive.skipped) summary.createDiv({ cls: "flomo-warning", text: `${archive.skipped} 条记录的内容或时间无法识别。` });

    const dates = this.contentEl.createEl("fieldset", { cls: "flomo-fieldset" });
    dates.createEl("legend", { text: "日期范围" });
    const row = dates.createDiv({ cls: "flomo-field-row" });
    const from = row.createEl("label", { text: "开始日期" }).createEl("input", { attr: { type: "date" } });
    from.addClass("flomo-focus-start");
    const to = row.createEl("label", { text: "结束日期" }).createEl("input", { attr: { type: "date" } });
    from.value = this.options.start;
    to.value = this.options.end;
    this.button(row, "全部日期", () => {
      from.value = start;
      to.value = end;
      update();
    });

    const modes = this.contentEl.createEl("fieldset", { cls: "flomo-fieldset" });
    modes.createEl("legend", { text: "导入方式" });
    const modeRow = modes.createDiv({ cls: "flomo-mode" });
    const buttons = new Map<Mode, HTMLButtonElement>();
    for (const [mode, label] of [["day", "按天合并"], ["card", "按卡片独立"]] as const) {
      buttons.set(mode, this.button(modeRow, label, () => {
        this.options.mode = mode;
        update();
      }));
    }
    const modeHint = modes.createDiv({ cls: "flomo-secondary" });
    const folder = this.contentEl.createDiv({ cls: "flomo-fieldset" });
    const folderLabelEl = folder.createEl("label", { text: "目标文件夹", attr: { for: "flomo-import-destination" } });
    folderLabelEl.addClass("flomo-field-title");
    const folderRow = folder.createDiv({ cls: "flomo-folder-row" });
    const folderInput = folderRow.createEl("input", {
      attr: { type: "text", id: "flomo-import-destination", placeholder: "仓库根目录" },
    });
    folderInput.value = this.options.folder || "/";
    this.button(folderRow, "搜索文件夹…", () => new FolderPicker(this.app, (path) => {
      folderInput.value = path || "/";
      update();
    }).open());
    folder.createDiv({ cls: "flomo-secondary", text: "可选已有文件夹，也可输入新路径。附件位置跟随「文件与链接」。" });
    const issue = this.contentEl.createDiv({ cls: "flomo-error", attr: { role: "status" } });
    const actions = this.footer();
    const stats = actions.parentElement!.createSpan({ cls: "flomo-secondary flomo-live-stats", attr: { "aria-live": "polite" } });
    actions.parentElement!.insertBefore(stats, actions);
    this.button(actions, "上一步", () => this.setStage("source"));
    const next = this.button(actions, "预览导入结果", () => void this.prepare(), true);
    for (const input of [from, to, folderInput]) {
      input.addEventListener("input", update);
      input.addEventListener("change", update);
    }

    const modal = this;
    function update() {
      modal.options.start = from.value;
      modal.options.end = to.value;
      const destination = folderPath(folderInput.value);
      if (destination !== undefined) modal.options.folder = destination;
      const selected = selectNotes(archive.notes, from.value, to.value);
      const count = modal.options.mode === "day" ? new Set(selected.map((note) => note.timestamp.slice(0, 10))).size : selected.length;
      const assets = new Set(selected.flatMap((note) => note.media.flatMap((media) => media.entry ? [media.entry] : []))).size;
      for (const [mode, button] of buttons) button.setAttribute("aria-pressed", String(mode === modal.options.mode));
      modeHint.setText(modal.options.mode === "day" ? "同一天的笔记合在一个文件中，以日期命名。" : "每条笔记单独保存为一个文件，用正文的第一行做文件名。");
      const warning = !from.value || !to.value || from.value > to.value ? "请选择有效的起止日期。"
        : destination === undefined ? "请输入有效的库内文件夹路径。"
        : !selected.length ? "所选日期没有笔记。" : "";
      issue.setText(warning);
      issue.hidden = !warning;
      stats.setText(`${selected.length} 条 Flomo 笔记 → ${count} 个笔记文件 · ${assets} 个附件`);
      next.disabled = Boolean(warning);
    }
    // Initialize after modal and all controls exist.
    update();
  }

  private async prepare(): Promise<void> {
    if (!this.archive || this.operation) return;
    this.operation = "正在准备预览";
    this.render();
    try {
      this.plan = await this.importer.prepare(this.archive, this.options);
      this.selected = 0;
      this.stage = "preview";
      this.error = "";
    } catch (error) {
      this.error = error instanceof Error ? error.message : String(error);
    } finally {
      this.operation = "";
      this.render();
    }
  }

  private renderPreview(): void {
    const plan = this.plan!;
    const summary = this.contentEl.createDiv({ cls: "flomo-source-summary" });
    summary.createDiv({ text: `笔记 · ${folderLabel(plan.options.folder)}` });
    if (plan.attachmentPaths.size) {
      summary.createDiv({ text: `附件 · ${folderLabel(plan.attachmentFolder)} · ${plan.record ? "已记录的路径" : "跟随「文件与链接」"}` });
    }
    if (plan.missing) summary.createDiv({ cls: "flomo-warning", text: `${plan.missing} 个附件在 ZIP 中找不到，将导入可读取的内容。` });
    if (plan.renamed && !plan.record) summary.createDiv({ cls: "flomo-warning", text: `${plan.renamed} 个同名文件已加编号，嵌入链接指向新文件。` });
    if (plan.record) summary.createDiv({ cls: "flomo-secondary", text: plan.record.completed ? "已导入过这批笔记。" : "检测到上次导入中断，可继续导入。" });

    const review = this.contentEl.createDiv({ cls: "flomo-review" });
    const nav = review.createDiv({ cls: "flomo-files", attr: { role: "group", "aria-label": "待生成文件" } });
    const panel = review.createDiv({ cls: "flomo-preview" });
    const controls = panel.createDiv({ cls: "flomo-preview-controls" });
    controls.createSpan({ cls: "flomo-secondary", text: "笔记预览" });
    const modes = controls.createDiv({ cls: "flomo-mode" });
    const body = panel.createDiv({ cls: "flomo-preview-body" });
    const fileButtons: HTMLButtonElement[] = [];
    const rendered = this.button(modes, "阅读", () => { this.raw = false; show(); });
    const raw = this.button(modes, "Markdown", () => { this.raw = true; show(); });
    const show = () => {
      this.revokeMedia();
      body.empty();
      raw.setAttribute("aria-pressed", String(this.raw));
      rendered.setAttribute("aria-pressed", String(!this.raw));
      for (const [index, button] of fileButtons.entries()) button.setAttribute("aria-current", String(index === this.selected));
      const file = plan.files[this.selected];
      if (!file) return;
      if (this.raw) body.createEl("pre").createEl("code", { text: renderMarkdown(file, plan) });
      else this.renderReading(body, file, plan);
    };
    for (const [index, file] of plan.files.entries()) {
      const button = this.button(nav, basename(file.path), () => { this.selected = index; show(); });
      fileButtons.push(button);
    }
    show();
    const actions = this.footer(`${plan.files.length} 个笔记文件 · ${plan.attachmentPaths.size} 个附件`);
    this.button(actions, "上一步", () => this.setStage("options"));
    this.button(actions, "另存 ZIP…", () => void this.saveZip());
    this.button(actions, plan.record?.completed ? "查看上次结果" : "导入当前库", () => void this.write(), true);
  }

  private renderReading(el: HTMLElement, file: PlannedNote, plan: ImportPlan): void {
    el.createDiv({ cls: "flomo-secondary", text: `created  ${file.created}  ·  type  ${noteTypes[plan.options.mode]}` });
    for (const [index, card] of file.notes.entries()) {
      if (index) el.createEl("hr");
      if (plan.options.mode === "day") el.createEl("h3", { text: noteTitle(card) });
      if (card.content) el.createEl("p", { cls: "flomo-note-text", text: card.content });
      for (const media of card.media) {
        const path = media.entry ? plan.attachmentPaths.get(media.entry) : undefined;
        const holder = el.createDiv({ cls: media.kind === "audio" ? "flomo-audio" : "flomo-image" });
        if (media.kind === "audio") holder.createEl("strong", { text: "语音" });
        if (path) {
          holder.createSpan({ text: basename(path), cls: "flomo-secondary" });
          const button = this.button(holder, "预览附件", () => void this.loadMedia(media, holder, button));
        } else {
          holder.createSpan({ text: `附件缺失 · ${basename(media.reference)}`, cls: "flomo-secondary" });
        }
        if (media.transcript) holder.createEl("p", { text: media.transcript });
      }
    }
  }

  private async loadMedia(media: Media, holder: HTMLElement, button: HTMLButtonElement): Promise<void> {
    if (!media.entry || !this.archive) return;
    button.disabled = true;
    try {
      const bytes = await this.archive.read(media.entry);
      if (!holder.isConnected) return;
      const url = URL.createObjectURL(new Blob([bytes], { type: mediaMime(media.entry) }));
      this.mediaUrls.add(url);
      if (media.kind === "image") holder.createEl("img", { attr: { src: url, alt: basename(media.entry) } });
      else holder.createEl("audio", { attr: { src: url, controls: "", preload: "metadata" } });
      button.remove();
    } catch (error) {
      if (holder.isConnected) {
        holder.createDiv({ cls: "flomo-warning", text: error instanceof Error ? error.message : String(error) });
        button.disabled = false;
      }
    }
  }

  private revokeMedia(): void {
    for (const url of this.mediaUrls) URL.revokeObjectURL(url);
    this.mediaUrls.clear();
  }

  private progress: Progress = (done, total) => {
    const progress = this.contentEl.querySelector<HTMLProgressElement>("progress");
    if (progress) {
      progress.max = Math.max(1, total);
      progress.value = done;
    }
    this.contentEl.querySelector(".flomo-progress-detail")?.setText(`${done} / ${total}`);
  };

  private async write(): Promise<void> {
    if (!this.archive || !this.plan || this.operation) return;
    this.operation = "正在写入当前仓库";
    this.error = "";
    this.render();
    try {
      const latest = await this.importer.prepare(this.archive, this.plan.options);
      if (!sameDestinations(this.plan, latest)) {
        this.plan = latest;
        this.stage = "preview";
        this.error = "仓库设置或文件已变化，预览已更新。请确认新位置后再导入。";
        return;
      }
      this.plan = latest;
      this.result = await this.importer.write(this.archive, latest, this.progress);
      this.stage = "result";
    } catch (error) {
      this.error = error instanceof Error ? error.message : String(error);
    } finally {
      this.operation = "";
      this.render();
    }
  }

  private async saveZip(): Promise<void> {
    if (!this.archive || !this.plan || this.operation) return;
    this.operation = "正在打包 ZIP";
    this.error = "";
    this.render();
    const name = `obsidian-notes-${new Date().toISOString().slice(0, 10)}.zip`;
    let disk: FileSystemWritableFileStream | undefined;
    try {
      const view = this.contentEl.ownerDocument.defaultView as SavePickerWindow | null;
      try {
        const handle = await view?.showSaveFilePicker?.({ suggestedName: name, types: [{ description: "ZIP", accept: { "application/zip": [".zip"] } }] });
        disk = await handle?.createWritable();
      } catch (error) {
        if (error instanceof DOMException && error.name === "AbortError") return;
        if (!(error instanceof DOMException && ["SecurityError", "NotSupportedError"].includes(error.name))) throw error;
      }
      if (disk) {
        const file = disk;
        await exportZip(this.archive, this.plan, this.progress, new WritableStream({
          write: (chunk: Uint8Array<ArrayBuffer>) => file.write(chunk),
        }));
        await file.close();
        new Notice("ZIP 已保存。");
        return;
      }
      const blob = await exportZip(this.archive, this.plan, this.progress);
      if (!blob) throw new Error("无法生成 ZIP。");
      const url = URL.createObjectURL(blob);
      const link = this.contentEl.createEl("a", {
        attr: { href: url, download: name },
      });
      link.click();
      link.remove();
      setTimeout(() => URL.revokeObjectURL(url), 30_000);
      new Notice("ZIP 已生成，请查看保存对话框或下载目录。");
    } catch (error) {
      await disk?.abort().catch(() => {});
      this.error = error instanceof Error ? error.message : String(error);
    } finally {
      this.operation = "";
      this.render();
    }
  }

  private renderResult(): void {
    const result = this.result!;
    const plan = this.plan!;
    this.contentEl.createEl("h3", { text: result.failures.length ? "部分文件尚未导入" : "导入完成" });
    const summary = this.contentEl.createDiv({ cls: "flomo-source-summary" });
    summary.createDiv({ text: `笔记 · ${folderLabel(plan.options.folder)} · ${result.files.length} 个文件` });
    if (result.assets.length) summary.createDiv({ text: `附件 · ${folderLabel(plan.attachmentFolder)} · ${result.assets.length} 个附件` });
    if (plan.missing) summary.createDiv({ cls: "flomo-warning", text: `源 ZIP 中有 ${plan.missing} 个缺失附件。` });
    if (result.failures.length) {
      const list = this.contentEl.createEl("ul", { cls: "flomo-result-list" });
      for (const issue of result.failures) list.createEl("li", { text: issue });
    }
    if (result.files.length || result.assets.length) {
      const details = this.contentEl.createEl("details", { cls: "flomo-result-files" });
      details.createEl("summary", { text: "查看已导入文件" });
      const list = details.createEl("ul", { cls: "flomo-result-list" });
      for (const path of [...result.files, ...result.assets]) {
        const item = list.createEl("li");
        const file = this.app.vault.getAbstractFileByPath(path);
        if (file instanceof TFile) {
          this.button(item, path, () => {
            void this.app.workspace.getLeaf(false).openFile(file).catch(() => new Notice("无法打开文件。"));
            this.close();
          });
        } else {
          item.setText(path);
        }
      }
    }
    const actions = this.footer();
    if (result.failures.length) this.button(actions, "重试导入", () => void this.write());
    this.button(actions, "完成", () => this.close(), true);
  }
}
