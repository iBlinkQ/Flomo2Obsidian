import assert from "node:assert/strict";
import { test } from "node:test";
import { countFlomoLinks, followupPrompt, followupWarning, titleTaskDescription } from "../src/followup";

test("counts flomo links by occurrence and deduplicates IDs across hosts and URL encodings", () => {
  const notes = [
    [
      "参考 https://v.flomoapp.com/mine/?memo_id=abc%3D 。",
      "[旧链接](https://flomoapp.com/mine?memo_id=abc&source=other)",
      "https://www.flomoapp.com/mine/?memo_id=def。",
      "`https://v.flomoapp.com/mine/?memo_id=inline`",
      "````",
      "https://v.flomoapp.com/mine/?memo_id=fenced",
      "```",
      "https://v.flomoapp.com/mine/?memo_id=stillfenced",
      "````",
      "https://v.flomoapp.com.evil.example/mine/?memo_id=external",
      "https://flomoapp.com/something-else?memo_id=notacard",
      "https://v.flomoapp.com/mine/?memo_id=",
    ].join("\n"),
    "https://v.flomoapp.com/mine/?memo_id=abc#target",
  ].map((content) => ({ timestamp: "2026-11-19 09:03:00", content, media: [] }));
  assert.deepEqual(countFlomoLinks(notes), { occurrences: 4, targets: 2 });
});

test("uses distinct warning thresholds and copies only the relevant prompt with absolute paths", () => {
  assert.equal(followupWarning("links", 49), undefined);
  assert.match(followupWarning("links", 50)!, /50 篇 flomo 笔记/);
  assert.equal(followupWarning("titles", 99), undefined);
  assert.match(followupWarning("titles", 100)!, /100 篇笔记生成标题/);
  assert.equal(titleTaskDescription("card"), "AI根据笔记正文总结生成标题。");

  const batch = {
    vaultName: "test", vaultPath: "/Users/demo/test", folderPath: "/Users/demo/test/flomo 导入",
    recordPath: "/Users/demo/test/.obsidian/plugins/flomo-zip-import/data.json", batchId: "batch",
  };
  for (const mode of ["day", "card"] as const) {
    for (const task of ["links", "titles"] as const) {
      const prompt = followupPrompt(task, mode, batch);
      assert.match(prompt, /^- 导入文件夹：\/Users\/demo\/test\/flomo 导入$/m);
      assert.match(prompt, /^- 批次记录文件：\/Users\/demo\/test\/\.obsidian\/plugins\/flomo-zip-import\/data\.json$/m);
      assert.match(prompt, /^- 批次 ID：batch$/m);
      assert.doesNotMatch(prompt, /卡片|导入方式：|用量提醒阈值|\bcard_note\b|\bdaily\b/);
      if (task === "links") {
        assert.equal(prompt.includes("#^笔记块ID"), mode === "day");
        assert.equal(prompt.includes("[[仓库内路径/文件名]]"), mode === "card");
      } else {
        assert.equal(prompt.includes("每个文件对应一天"), mode === "day");
        assert.equal(prompt.includes("每个文件对应一篇笔记"), mode === "card");
        if (mode === "card") {
          assert.match(prompt, /按实际解析到的完整路径区分同名笔记/);
          assert.match(prompt, /批次记录由插件自动同步，data\.json 只读核验/);
          assert.match(prompt, /文件数或链接数与确认清单不一致.*保留弹窗并请我确认/);
        } else {
          assert.match(prompt, /只有跳到这篇每日笔记旧标题的内链需要更新/);
          assert.match(prompt, /指向同名文件或固定块 ID 的链接可以继续使用/);
        }
      }
    }
  }
});
