---
description: Convert PDFs, Word, PowerPoint or Excel files into a Markdown corpus this repo can use as context
argument-hint: <file-or-folder> [output-dir]
allowed-tools: Bash, Read, Write, Glob, Grep
---

Digest the document(s) at `$1` into reusable Markdown context.

Output directory: `$2` if given, otherwise `.docling/` in the current
working directory.

## Steps

1. **Check the source exists** and list what you're about to convert
   (`ls`/`find`). If `$1` is a folder, count the files and report the count
   before starting — the user should know if it's 200 PDFs.

2. **Decide on OCR.** Digital PDFs (exported from Word, LaTeX, a browser)
   don't need it and run much faster without. Scans and photographed pages do.
   If unsure, sample one file with `pdffonts` or just try `--no-ocr` first and
   check the output isn't empty.

3. **Convert**, in the background — this is slow:

   ```bash
   docling convert "$1" --to md --output <output-dir>   # add --no-ocr if digital
   ```

4. **Write `<output-dir>/INDEX.md`**: one line per converted document giving
   its filename, its source path, and a one-sentence description of what it
   covers, based on the headings. This is what future sessions read first
   instead of opening every file.

5. **Gitignore the output** unless the user says otherwise — add
   `<output-dir>/` to `.gitignore` if it isn't already there. Converted
   Markdown is a derived artifact.

6. **Report**: how many files converted, total size, anything that failed, and
   the one-line instruction for using it later — point future sessions at
   `<output-dir>/INDEX.md`, and tell them to `rg` the corpus rather than
   reading files whole.

## Rules

- Do **not** read the converted Markdown into context to "verify" it. Check
  file sizes and skim `INDEX.md`. A corpus can be millions of tokens.
- If a file fails to convert, note it and keep going — don't abort the batch.
- If `$1` is empty, ask which document or folder to digest.
