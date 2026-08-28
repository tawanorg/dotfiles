---
name: docling
description: Use when the user points at a PDF, Word, PowerPoint, Excel, HTML or scanned document and wants its contents read, summarised, searched, or turned into reusable context. Covers the docling MCP tools and the docling CLI, and which of the two to reach for.
---

# Digesting documents with Docling

Docling turns PDF/DOCX/PPTX/XLSX/HTML/images into structured text, locally and
offline. Two front ends are installed, and picking the wrong one is the main
way this goes badly.

## Choose the front end first

| Situation | Use | Why |
|---|---|---|
| One document, answering questions about it now | **MCP tools** | No files left behind; you read only the parts you need |
| A document you'll come back to across sessions | **CLI** → Markdown on disk | Converting once beats re-converting every session |
| A folder / whole corpus | **CLI** | Batch, and the output is greppable |
| Building context for a repo | **CLI** | Markdown in the repo is searchable by every future session |

Cost depends entirely on the format. Office and HTML files are parsed
structurally and convert in milliseconds. PDFs and images go through layout
detection and OCR — seconds to minutes each, CPU-bound. So the "put it on disk"
advice really means *PDFs*; re-converting a PPTX is free.

## The iron rule: never dump a whole document into context

A 40-page PDF is tens of thousands of tokens. Both front ends give you a way to
avoid that, and you should always take it.

- **MCP**: get the overview, search it, then pull only the anchors you need.
- **CLI**: write Markdown to disk, then `rg` for the part you want and `Read`
  that slice. Do not `cat` the whole thing.

Read the whole document only when the user explicitly asks for a full
translation, rewrite, or end-to-end summary.

## MCP workflow

The `docling` MCP server runs in local mode with the `conversion` and
`manipulation` toolgroups.

1. `convert_document_into_docling_document` with a local path or URL →
   returns a `document_key`. Cache is per-server-process, so the key is good
   for the rest of the session.
   (`is_document_in_local_cache` checks before you pay for a re-convert;
   `convert_directory_files_into_docling_document` does a whole folder.)
2. `get_overview_of_document_anchors` → the structure, as `#/texts/N` anchors.
   This is your table of contents. Start here, always.
3. `search_for_text_in_document_anchors` → which anchors mention a term.
4. `get_text_of_document_item_at_anchor` → the actual text of those anchors.

`update_text_of_document_item_at_anchor` and `delete_document_items_at_anchors`
edit the **cached copy only** — the source file is never touched, and the edit
is lost when the session ends. They are not a way to edit a PDF.

## CLI workflow

```bash
docling convert report.pdf --to md                     # → report.md
docling convert ./papers --to md --output ./context    # whole folder
docling convert deck.pptx --to md --to json            # several formats at once
docling convert scan.pdf --to md --no-ocr              # skip OCR: much faster
```

`--to` accepts `md`, `json`, `yaml`, `html`, `text`, `doctags`, `vtt`, and
`chunks` (pre-chunked for RAG). Markdown is the right default for context.

OCR is **on by default** and is most of the runtime. Digital PDFs — anything
exported from Word, LaTeX, or a browser — do not need it; pass `--no-ocr`.
Keep OCR only for scans and photographed pages.

Run PDF batches in the background — a folder of them can take many minutes.
Office-format folders finish fast enough to run inline.

## Operational notes

- **First run downloads models** (~190 MB, to `~/.cache/huggingface` and the
  tool venv). After that it is fully offline.
- Both tools live in isolated uv envs on Python 3.13. Upgrade with
  `uv tool upgrade docling docling-mcp`.
- Converted Markdown is a *derived artifact*. Write it somewhere gitignored
  (`.docling/` by convention) unless the user wants it committed.
