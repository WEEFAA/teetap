# ADR-0004: `pipe` is the capture primitive; `run` is sugar over it

**Status**: Accepted

`teetap pipe <name>` is a sink: stdin → session marker → `tee -a` → stdout passthrough → end marker on EOF. `teetap run <name> -- <cmd>` is implemented on top of it (merging stderr, enriching markers with the command line and exit code). This gives one code path for writing and makes the plugging mechanism universal: shell functions, aliases, mid-pipeline taps, `pm2 logs --raw`, `kubectl logs -f`, or an ssh'd remote tail can all feed the same sink — satisfying the composable-interface criterion with one subcommand instead of per-producer integrations.

The tool is runtime-agnostic by decision: no default command, no assumption of a JavaScript (or any) ecosystem anywhere in the tool, docs, or skill.

## Consequences

Inherent sink limitations are accepted: `pipe` cannot know the producer's exit code (it only sees EOF), and pipe-form users must redirect stderr themselves. `run` exists precisely to cover the common case where those matter.
