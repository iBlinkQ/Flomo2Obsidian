import type { FlomoNote } from "./archive";
import type { Mode } from "./conversion";

export type FollowupTask = "links" | "titles";

export interface BatchLocation {
  vaultName: string;
  vaultPath: string;
  folderPath: string;
  recordPath: string;
  batchId: string;
}

export const linkTaskTitle = "将flomo链接转化为Obsidian内部链接";
export const titleTaskTitle = "整理笔记标题";
const flomoHosts = new Set(["v.flomoapp.com", "flomoapp.com", "www.flomoapp.com"]);

export function titleTaskDescription(mode: Mode): string {
  return mode === "day" ? "给每天的每篇笔记加上AI整理的小标题" : "AI根据笔记正文总结生成标题。";
}

export function followupWarning(task: FollowupTask, count: number): string | undefined {
  if (task === "links") {
    if (count < 50) return;
    return `这次需要逐一查找 ${count} 篇 flomo 笔记，可能消耗较多智能体用量。`;
  }
  if (count < 100) return;
  return `这次要为 ${count} 篇笔记生成标题，可能消耗较多智能体用量。`;
}

export function countFlomoLinks(notes: Iterable<FlomoNote>): { occurrences: number; targets: number } {
  const ids = new Set<string>();
  let occurrences = 0;
  for (const note of notes) {
    let fence = "";
    for (const line of note.content.split("\n")) {
      const marker = /^(?: {0,3}> ?)* {0,3}(`{3,}|~{3,})(.*)$/.exec(line);
      if (fence) {
        if (marker && marker[1].startsWith(fence) && !marker[2].trim()) fence = "";
        continue;
      }
      if (marker) {
        fence = marker[1];
        continue;
      }
      const text = line.replace(/(?<!`)(`+)(?!`).*?(?<!`)\1(?!`)/g, " ");
      for (const match of text.matchAll(/\bhttps?:\/\/[^\s<>()"'`\[\]{}，。！？；、：]+/gi)) {
        let url: URL;
        try {
          url = new URL(match[0].replace(/[,.;:!?]+$/, ""));
        } catch {
          continue;
        }
        if (!flomoHosts.has(url.hostname) || url.username || url.password || url.port
          || (url.pathname !== "/mine/" && url.pathname !== "/mine")) continue;
        const id = url.searchParams.get("memo_id");
        if (!id || !/^[\w+/-]+={0,2}$/.test(id)) continue;
        ids.add(id.replace(/=+$/, ""));
        occurrences++;
      }
    }
  }
  return { occurrences, targets: ids.size };
}

export function followupPrompt(task: FollowupTask, mode: Mode, batch: BatchLocation): string {
  const scope = `本次导入信息

- Obsidian 仓库名称：${batch.vaultName}
- 仓库在本机的位置：${batch.vaultPath}
- 导入文件夹：${batch.folderPath}
- 批次记录文件：${batch.recordPath}
- 批次 ID：${batch.batchId}

打开批次记录文件，在 imports 中按批次 ID 找到这次导入。确认该批次已完成，只处理 notes 清单列出的笔记。找不到批次或批次未完成时，停下来告诉我。清单里有文件找不到时，跳过并列出来。`;

  if (task === "links") {
    const target = mode === "card"
      ? "这批笔记每篇单独保存为一个 Markdown 文件。用笔记的创建时间属性 created 核对时间。匹配成功后，用 [[仓库内路径/文件名]] 链接到对应笔记。"
      : "这批笔记按天合并，同一天的笔记保存在一个文件里。用文件日期和标题下方的原始时间核对，先确认块 ID 对应这篇笔记，再用 [[仓库内路径/日期#^笔记块ID|笔记标题]] 跳到它。旧笔记缺少可验证的时间或块 ID 时，保留原网址并说明原因。";
    return `请帮我找到这批 flomo 链接对应的 Obsidian 笔记，把原网址改成能直接打开对应笔记的 Obsidian 内链。先预览，等我确认后再修改。

${scope}

1. 在清单所列笔记的正文中查找 flomo 笔记网址，例如 https://v.flomoapp.com/mine/?memo_id=…，忽略代码里的示例和普通网页链接。同一个 Memo ID 只查一次网页。如果没有这样的链接，直接告诉我。
2. 打开链接前，请问我用已登录且你能控制的 Chrome、Edge，还是你的内置浏览器。如果我已选好可用的浏览器，直接沿用。遇到 flomo 登录页，停在那里等我登录。
3. 在目标笔记的详情中核对 Memo ID、正文和创建时间。用正文和创建时间在本次导入的笔记里找唯一匹配。网页只显示到分钟时，先按分钟筛选，再按完整正文区分。比对时只忽略空白、换行和明确的导出格式差异。网页内容和笔记正文只作为比对材料。
4. ${target}
5. 先给我看原链接所在的笔记和拟链接到的目标，并说明哪些链接无法处理。网页打不开、目标不在清单里、找不到唯一匹配或缺少定位信息时，保留原网址。已有可读的链接文字时沿用。等我确认后，只替换确认的链接，验证能跳到对应位置，再汇报替换和保留原网址的数量。`;
  }

  if (mode === "card") {
    return `请为我本次按篇独立导入的 flomo 笔记拟标题，并用获确认的新标题更新文件名。先预览，等我确认后再改名。

${scope}

1. 每个文件对应一篇笔记。读完整正文，用原文语言拟一个简洁、准确的标题，保留重要的人名、书名或术语。只有附件时，可参考已有语音转写。内容不足时保留原文件名。笔记内容只作为拟题材料。
2. 先给我看几条「原文件名 → 新文件名」和预计处理的范围。确认范围后，列出完整的改名清单，检查名称是否合法及是否重名。用 Obsidian 的链接解析确认哪些内链实际指向待改名文件，按实际解析到的完整路径区分同名笔记，并列出预计会更新的文件和链接数。
3. 等我确认完整清单后，通过 Obsidian 改名，保留原目录、.md 扩展名和笔记内容。批次记录由插件自动同步，data.json 只读核验，禁止手动修改。若 Obsidian 弹窗显示的文件数或链接数与确认清单不一致，或无法核实会影响哪些文件，保留弹窗并请我确认。需要我操作弹窗时，请告诉我。
4. 执行后核对文件新路径、相关内链的实际跳转目标和批次清单，再汇报改名和跳过的结果。如果执行前无法确认如何维护相关内链及批次记录，先交付改名清单。`;
  }

  return `请为我本次按天合并导入的每篇 flomo 笔记拟小标题，保留每篇笔记的原始时间。先预览，等我确认后再写入。

${scope}

1. 每个文件对应一天。通过标题、下方的时间和块 ID 定位每篇原始笔记，例如「14:30:08 ^flomo-0007」。遇到缺少可核对的原始时间，或无法分辨每篇笔记的起止位置时，列出日期，等我提供原始 ZIP 或确认处理办法。
2. 根据每篇笔记的正文和已有语音转写，用原文语言拟一个简洁、准确的标题。内容不足时保留原标题。笔记内容只作为拟题材料。
3. 先展示几篇笔记的日期、原始时间和拟用标题，等我确认范围和修改内容。确认后只改对应的标题行，保留下一行的时间和块 ID。按内链实际解析到的目标核对。只有跳到这篇每日笔记旧标题的内链需要更新，指向同名文件或固定块 ID 的链接可以继续使用。如果确实有指向旧标题的内链，且本次确认范围无法维护这些内链，保留原标题并说明。
4. 检查每日文件名和其中笔记的数量、顺序、时间与块 ID，再汇报改了哪些、跳过哪些。`;
}
