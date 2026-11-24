import assert from "node:assert/strict";
import { test } from "node:test";
import { parseHTML } from "linkedom";
import { BlobWriter, TextReader, ZipWriter } from "@zip.js/zip.js";
import { FlomoArchive, parseFlomoHtml } from "../src/archive";
import { attachmentDirectory, batchKey, buildPlan, folderPath, renderMarkdown, selectNotes } from "../src/conversion";

const doc = parseHTML("<html><body></body></html>").document as unknown as Document;
const member = (time: string, text: string, media = "") =>
  `<div class="memo"><div class="time">${time}</div><div class="content">${text}</div>${media}</div>`;
const html = [
  member("2026-11-19 09:03:00", "<p>第一条<br>第二行 #标签</p><ul><li>列表</li></ul>",
    '<div class="files"><img src="file/图%20片.png"><img src="https://example.invalid/remote.png"></div>'),
  member("2026-11-19 23:59:59", "<p>第一条</p>",
    '<div class="audio-player"><audio src="file/音频.m4a"></audio><div class="audio-player__content">第一行<br>第二行</div></div>'),
  member("2026-11-20 00:00:00", "<p>下一天</p>"),
  member("2026-02-30 12:00:00", "<p>无效日期</p>"),
].join("\n");

test("reads nested Flomo exports, preserves lists and audio transcript, and ignores remote media", async () => {
  const output = new ZipWriter(new BlobWriter(), { useWebWorkers: false });
  await output.add("export/index.html", new TextReader(html));
  await output.add("export/file/图 片.png", new TextReader("a"));
  await output.add("export/file/音频.m4a", new TextReader("b"));
  const archive = await FlomoArchive.open(await output.close(), doc);
  try {
    assert.equal(archive.notes.length, 3);
    assert.equal(archive.skipped, 1);
    assert.equal(archive.notes[0].content, "第一条\n第二行 #标签\n- 列表");
    assert.equal(archive.notes[0].media[0].entry, "export/file/图 片.png");
    assert.equal(archive.notes[0].media[1].entry, undefined);
    assert.equal(archive.notes[1].media[0].transcript, "第一行\n第二行");
    const selected = selectNotes(archive.notes, "2026-11-19", "2026-11-19");
    assert.equal(selected.length, 2);
    assert.equal((await batchKey(archive, selected, "day", "日记")).length, 64);
    assert.equal(new TextDecoder().decode(await archive.read("export/file/音频.m4a")), "b");
  } finally {
    await archive.close();
  }
});

test("matches all four attachment policies and rejects invalid paths", () => {
  assert.equal(attachmentDirectory("/", "笔记/归档"), "");
  assert.equal(attachmentDirectory("素材/图片", "笔记/归档"), "素材/图片");
  assert.equal(attachmentDirectory("./", "笔记/归档"), "笔记/归档");
  assert.equal(attachmentDirectory("./附件", "笔记/归档"), "笔记/归档/附件");
  assert.equal(attachmentDirectory("./附件", ""), "附件");
  assert.equal(folderPath("../outside"), undefined);
  assert.equal(folderPath("用作/K/NUL.txt"), undefined);
});

test("deduplicates filenames, preserves attachment links, and groups by selected mode", () => {
  const paths = new Set(["file/图 片.png", "file/音频.m4a"]);
  const notes = selectNotes(parseFlomoHtml(doc, html, "index.html", paths).notes, "2026-11-19", "2026-11-19");
  const options = { start: "2026-11-19", end: "2026-11-19", mode: "day", folder: "日记" } as const;
  const day = buildPlan("day", notes, options, "素材", ["日记/2026-11-19.md", "素材/音频.m4a"]);
  assert.equal(day.files[0].path, "日记/2026-11-19-2.md");
  assert.equal(day.renamed, 2);
  assert.equal(day.missing, 1);
  assert.equal(day.attachmentPaths.get("file/音频.m4a"), "素材/音频-2.m4a");
  const markdown = renderMarkdown(day.files[0], day);
  assert.equal(markdown.split("\n\n", 1)[0], "---\ncreated: 2026-11-19\ntype: daily\n---");
  assert.match(markdown, /# 第一条/);
  assert.match(markdown, /> \[!tip\]\+ 语音\n> !\[\]\(\.\.\/%E7%B4%A0%E6%9D%90\/%E9%9F%B3%E9%A2%91-2\.m4a\)\n> 第一行\n> 第二行/);
  assert.doesNotMatch(markdown, /example.invalid/);
  const card = buildPlan("card", notes, { ...options, mode: "card" }, "./附件", []);
  assert.deepEqual(card.files.map((file) => file.path), ["日记/第一条.md", "日记/第一条-2.md"]);
  const cardMarkdown = renderMarkdown(card.files[1], card);
  assert.equal(cardMarkdown.split("\n\n", 1)[0], "---\ncreated: 2026-11-19 23:59:59\ntype: card_note\n---");
  assert.ok(cardMarkdown.includes("![](./%E9%99%84%E4%BB%B6/%E9%9F%B3%E9%A2%91.m4a)"));
});
