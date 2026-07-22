---
name: local-dev
version: 1.0.0
description: Bring this repo's local development environment up from scratch.
category: local-dev
triggers:
  - local dev setup
  - run repo locally
  - start dev server
  - bring up local stack
author: autobuild-setup
created: 2026-07-22
---

## Prerequisites
- **CircleCI CLI** — verified v0.1.38646. Not preinstalled in the sandbox; install it first (see Install).
- No language runtime or package manager is required — this repo has no application code.
- **Docker:** not available in this sandbox. This blocks `circleci local execute`; config validation is used as the primary verification instead.

## Install
```bash
# Install the CircleCI CLI (not preinstalled)
curl -fLSs https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/main/install.sh | DESTDIR=$HOME/bin bash
export PATH="$HOME/bin:$PATH"
circleci version   # verified: 0.1.38646
```
There is no dependency-install step — the repo has no package manifest.

## Environment
No environment variables or secrets are required for local verification; there is no `.env` file. CircleCI runtime variables (e.g. `CIRCLE_CONTINUATION_KEY`) are injected only by the CircleCI platform during an actual pipeline run and are not needed locally.

## Start
There is no long-running server or open port. The "primary flow" is CircleCI config verification:
```bash
circleci config validate .circleci/config.yml            # setup config
circleci config validate .circleci/continue-config.yml   # continued config
circleci config process .circleci/config.yml             # compile + expand orbs
```

## Verify Primary User Flow
1. Validate the setup config → `Config file at .circleci/config.yml is valid.` (evidence: file `fl_WMiEeqE1`)
2. Validate the continuation config → `…continue-config.yml is valid.` (evidence: `fl_6kndJ4uB`)
3. Process the setup config → orbs `circleci/path-filtering@0.1.0` and `circleci/continuation@0.2.0` resolve and the path→parameter mapping expands (evidence: `fl_GzGmMnWl`)
4. Simulate `job_a` (triggered by a `path_a/**` change): `echo "Running job a" && cat path_a/README.md` (evidence: `fl_VqYeDRLl`)
5. Simulate `job_b` (triggered by a `path_b/**` change): `echo "running job b" && cat path_b/README.md` (evidence: `fl_TMnSMRsb`)

## Verified Commands
- Lint/validate: `circleci config validate .circleci/config.yml` (and `.circleci/continue-config.yml`)
- Compile: `circleci config process .circleci/config.yml`
- Typecheck / unit tests: not applicable — no compiled code or test suite in this repo.
- Scoped variant for changed files only: `circleci config validate <path-to-config>`.

## Sandbox Snapshot
- snapshotId: `13pkl2kbxjerk0tf7k1s:default` — restoring this snapshot reproduces the verified-healthy state from install (CircleCI CLI already on `$HOME/bin`).

## Known Blockers / Workarounds
- **docker_unavailable** (non-fatal): no Docker daemon in the sandbox, so `circleci local execute` cannot run containerized jobs. Workaround: validate configs with `circleci config validate` and run the job step commands directly (`echo` / `cat`). This produced `dev_stack_healthy: true`.
- The CircleCI CLI is not preinstalled — install it first (see Install).

