# CircleCI `persist_to_workspace` Glob Pattern Test Suite

This branch exercises every glob pattern supported by CircleCI's `persist_to_workspace` step. The glob syntax comes from Go's [`filepath.Match`](https://golang.org/pkg/path/filepath/#Match).

## How It Works

Each of the **23 workflows** is fully isolated:

1. A **persist job** creates an identical rich directory tree, then calls `persist_to_workspace` with a single glob pattern
2. A **verify job** attaches the workspace and lists exactly which files arrived

Because each test runs in its own workflow, workspaces don't bleed between tests (workspaces are additive *within* a workflow but separate *across* workflows).

## Test Directory Structure

The following tree is created in every persist job:

```
/tmp/workspace/
├── readme.txt, notes.md, app.log, data.json, data.xml
├── config.yaml, config.yml, report.csv, Makefile
├── .hidden
├── a.txt, b.txt, c.txt, 1.txt, 2.txt, ab.txt
├── file[1].txt, file with spaces.txt
├── src/
│   ├── main/java/com/example/Main.java, Utils.java
│   └── test/java/com/example/MainTest.java
├── build/
│   ├── libs/app.jar, app.war
│   └── reports/tests/index.html
├── docs/
│   ├── README.md
│   └── api/reference.html
├── logs/2024/
│   ├── 01/app.log
│   └── 02/app.log
└── dist/
    ├── css/style.css
    ├── js/app.js, vendor.js
    └── images/logo.png, icon.svg
```

## Glob Patterns Under Test

| # | Workflow | Glob Pattern | What It Tests |
|---|---------|-------------|---------------|
| 1 | `test-01-star-extension` | `*.txt` | Star wildcard with extension (root level only, `*` won't cross `/`) |
| 2 | `test-02-star-in-dir` | `build/libs/*` | Star inside a specific subdirectory |
| 3 | `test-03-question-mark` | `?.txt` | Question mark — single character match |
| 4 | `test-04-char-class` | `[abc].txt` | Character class — explicit set |
| 5 | `test-05-char-range` | `[a-c].txt` | Character range |
| 6 | `test-06-negated-class` | `[^0-9].txt` | Negated character class — NOT digits |
| 7 | `test-07-hierarchical-star` | `dist/*/app.*` | Hierarchical star (wildcard in both dir and file segments) |
| 8 | `test-08-extension-class` | `build/libs/*.[jw]ar` | Character class in extension |
| 9 | `test-09-whole-directory` | `docs` | Whole directory by name (no glob, no slash) |
| 10 | `test-10-deep-nested-star` | `logs/2024/*/app.log` | Deep nested star |
| 11 | `test-11-question-in-dir` | `logs/2024/0?/app.log` | Question mark in a directory segment |
| 12 | `test-12-multiple-paths` | `*.md` + `*.json` + `build/libs/*.jar` | Multiple paths in one `persist_to_workspace` |
| 13 | `test-13-hidden-file` | `.hidden` | Exact dotfile name |
| 14 | `test-14-dot-star` | `.*` | Dot-star — match all hidden/dotfiles |
| 15 | `test-15-star-in-extension` | `config.y*ml` | Star in extension (matches both `yaml` and `yml`) |
| 16 | `test-16-bare-star` | `*` | Bare star — does it match everything at root? Does it recurse into dirs? |
| 17 | `test-17-exact-path` | `src/main/java/com/example/Main.java` | Exact file path with no glob characters |
| 18 | `test-18-multi-level-star` | `src/*/java/com/example/*.java` | Stars at multiple path levels |
| 19 | `test-19-file-with-spaces` | `file with spaces.txt` | Spaces in filename |
| 20 | `test-20-dot-everything` | `.` | Dot — persist the entire tree |
| 21 | `test-21-star-slash-star` | `*/*.js` | Star-slash-star — one directory level deep |
| 22 | `test-22-dir-no-slash` | `build` | Directory name without trailing slash |
| 23 | `test-23-dir-with-slash` | `build/` | Directory name with trailing slash |

## Glob Syntax Reference

From Go's `filepath.Match`:

```
*        matches any sequence of non-Separator characters
?        matches any single non-Separator character
[abc]    character class (must be non-empty)
[a-z]    character range (lo-hi inclusive)
[^abc]   negated character class
\c       matches character c literally
```

Key behavior: `*` does **not** cross directory separators (`/`). To match across directories you need explicit path segments like `dir/*/file` or use `.` to persist the entire tree.

## Reading Results

Check the output of each **verify** job in CircleCI. Each one prints:
- The glob pattern being tested
- Every file that arrived via `attach_workspace`
- Every directory that arrived
- A total file count
