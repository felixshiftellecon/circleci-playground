# Codebase Map

| Directory | Purpose |
|---|---|
| `.circleci` | CircleCI dynamic configuration — the setup pipeline (path-filtering + continuation orbs) and the continued pipeline defining `job_a` / `job_b` |
| `path_a` | Marker directory; a change under `path_a/**` sets `run-path-a=true` and triggers `job_a`. Contains a README. |
| `path_b` | Marker directory; a change under `path_b/**` sets `run-path-b=true` and triggers `job_b`. Contains a README. |

