import { App, Notice, Plugin, PluginSettingTab, Setting, addIcon, removeIcon } from "obsidian";
import { folderPath, type ImportRecord, type Mode } from "./conversion";
import { Importer } from "./importer";
import { FolderPicker, ImportModal } from "./ui";

interface Settings {
  folder: string;
  mode: Mode;
}

interface PluginData {
  defaults: Settings;
  imports: Record<string, ImportRecord>;
}

const ribbonIcon = "flomo-zip-import-mark";
const ribbonSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4.8 13.6V6.6c0-2.2 1.4-3.4 3.5-2.9M2.8 8.1h5.5"/>
  <circle cx="16.2" cy="8.5" r="4.6"/>
  <path d="M2.9 17.2c4.9 5.4 13.6 5.3 18.1-1m-3.6.7 3.8-.9-.1 3.8"/>
</svg>`;

export default class FlomoZipImport extends Plugin {
  private data!: PluginData;
  private importer!: Importer;
  private modal?: ImportModal;
  private saveQueue: Promise<void> = Promise.resolve();

  async onload(): Promise<void> {
    const saved = await this.loadData() as Partial<PluginData> | null;
    this.data = {
      defaults: {
        folder: folderPath(saved?.defaults?.folder ?? "Flomo 导入") ?? "Flomo 导入",
        mode: saved?.defaults?.mode === "card" ? "card" : "day",
      },
      imports: saved?.imports ?? {},
    };
    this.importer = new Importer(this.app, this.data.imports, async (key, record) => {
      await this.persist(() => { this.data.imports[key] = record; });
    });
    addIcon(ribbonIcon, ribbonSvg);
    this.register(() => removeIcon(ribbonIcon));
    this.addRibbonIcon(ribbonIcon, "导入 Flomo 笔记", () => this.openImporter());
    this.addCommand({
      id: "import-flomo-zip",
      name: "导入 Flomo 笔记",
      callback: () => this.openImporter(),
    });
    this.addSettingTab(new FlomoSettingsTab(this.app, this));
  }

  onunload(): void {
    this.modal?.close();
  }

  get defaults(): Readonly<Settings> {
    return this.data.defaults;
  }

  async setDefaults(patch: Partial<Settings>): Promise<void> {
    await this.persist(() => { Object.assign(this.data.defaults, patch); });
  }

  private persist(change: () => void): Promise<void> {
    // Serialize settings and import records so a later save cannot overwrite an in-progress import.
    const save = this.saveQueue.then(async () => {
      change();
      await this.saveData(this.data);
    });
    this.saveQueue = save.catch(() => {});
    return save;
  }

  openImporter(): void {
    if (this.modal) {
      this.modal.modalEl.focus();
      return;
    }
    this.modal = new ImportModal(this.app, this.importer, this.defaults, () => { this.modal = undefined; });
    this.modal.open();
  }
}

class FlomoSettingsTab extends PluginSettingTab {
  constructor(app: App, private readonly flomo: FlomoZipImport) {
    super(app, flomo);
  }

  display(): void {
    const { containerEl } = this;
    containerEl.empty();
    new Setting(containerEl)
      .setName("默认导入方式")
      .addDropdown((dropdown) => dropdown
        .addOption("day", "按天合并")
        .addOption("card", "按卡片独立")
        .setValue(this.flomo.defaults.mode)
        .onChange((value) => void this.save({ mode: value === "card" ? "card" : "day" })));

    let applyFolder: (value: string) => void;
    const folder = new Setting(containerEl)
      .setName("默认目标文件夹")
      .setDesc("选择已有文件夹，或输入路径供下次导入。");
    folder.addText((input) => {
      applyFolder = (path) => input.setValue(path || "/");
      applyFolder(this.flomo.defaults.folder);
      input.onChange((value) => {
        const path = folderPath(value);
        if (path !== undefined) void this.save({ folder: path });
      });
      input.inputEl.addEventListener("blur", () => {
        if (folderPath(input.getValue()) === undefined) {
          applyFolder(this.flomo.defaults.folder);
          new Notice("请输入有效的库内文件夹路径。");
        }
      });
    });
    folder.addButton((button) => button.setButtonText("搜索…").onClick(() => {
      new FolderPicker(this.app, (path) => {
        applyFolder(path);
        void this.save({ folder: path });
      }).open();
    }));

    new Setting(containerEl)
      .setName("附件位置")
      .setDesc("沿用当前仓库「文件与链接」中的附件存放规则。");
    new Setting(containerEl)
      .setName("从 Flomo 导入")
      .addButton((button) => button.setButtonText("开始导入…").setCta().onClick(() => this.flomo.openImporter()));
  }

  private async save(patch: Partial<Settings>): Promise<void> {
    try {
      await this.flomo.setDefaults(patch);
    } catch {
      new Notice("无法保存 Flomo 导入设置。");
    }
  }
}
