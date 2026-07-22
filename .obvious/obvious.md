# Repo guidance

## Codebase Map

See `.obvious/codebase-map.md`.

## Rules

<!-- synthesized from: README.md, path_a/README.md, path_b/README.md (only guidance files found in SCAN) — agent-relevant rules only -->

- This repo is a minimal CircleCI **dynamic configuration** demo (path-filtering + continuation orbs). It has no application code, package manager, or language runtime — only `.circleci/` configs and per-path `README.md` marker files.
- The only meaningful change surface is `.circleci/config.yml` (setup pipeline) and `.circleci/continue-config.yml` (continued pipeline defining `job_a` / `job_b`). Always validate edits with `circleci config validate <path>` before committing.
- Path routing: a change under `path_a/**` sets `run-path-a=true` (runs `job_a`); a change under `path_b/**` sets `run-path-b=true` (runs `job_b`). The mapping lives in the `path-filtering/filter` step of `config.yml`.
- **Known gotcha:** the tag/API continuation jobs in `config.yml` reference `continue_config.yml` (underscore), but the file on disk is `continue-config.yml` (hyphen). The path-filtering job uses the correct hyphenated path. Preserve existing behavior unless explicitly asked to fix it.
- No `AGENTS.md`, `CLAUDE.md`, or `CONTRIBUTING.md` exists — there are no additional repo-authored agent rules.

## Local Verification

> **Warning:** Running full-repo typecheck, lint, or tests may OOM or timeout in the sandbox for large repos.
> Use the scoped commands below when verifying changes.

### Verified Commands

- **Validate setup config:** `circleci config validate .circleci/config.yml` — verified
- **Validate continuation config:** `circleci config validate .circleci/continue-config.yml` — verified
- **Compile / expand orbs:** `circleci config process .circleci/config.yml` — verified
- **Install CircleCI CLI (not preinstalled):** `curl -fLSs https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/main/install.sh | DESTDIR=$HOME/bin bash` — verified (v0.1.38646)

> No typecheck or unit-test tooling exists in this repo; verification == config validation. `circleci local execute` requires a Docker daemon, which is unavailable in this sandbox.

### Scoped Workflow

Run this command to verify a changed config file without triggering a full-repo scan:

1. **Lint/validate a changed config:** `circleci config validate <path-to-config>`

## Sandbox Snapshot

- **Snapshot ID:** `13pkl2kbxjerk0tf7k1s:default`
- **Captured:** `2026-07-22T21:33:49.148Z`
- **Dev stack healthy:** yes

## Atlas

Product Atlas already fully maps this repo (13 nodes, all complete). No new nodes were created; 2 existing nodes were reinforced with repo-file provenance:

- `setup-pipeline` (surface) ← `.circleci/config.yml`
- `continued-pipeline` (surface) ← `.circleci/continue-config.yml`

Existing hierarchy: `circleci-playground` (product) → `dynamic-configuration` / `path-based-workflow-routing` (concepts) → `setup-pipeline`, `continued-pipeline` (surfaces) → jobs & conditional workflows (features) + `base-executor-environment` (infrastructure).

## Security Scan

> **Note:** security_scan_not_triggered — the `trigger_security_onboarding` tool is not available in this worker's toolset. Trigger manually using the `trigger_security_onboarding` tool with the target commit SHA (`36215fdb67348e6c85712af6c593d3d3abe95718`) when available.

## Runbooks

[Populated by autobuild-runbooks skill when requested. See `.obvious/runbooks/` after that skill runs.]

