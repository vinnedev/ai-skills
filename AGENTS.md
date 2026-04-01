# Repository Expectations

- This repository is the source of truth for the Claude and Codex bootstrap payloads.
- Keep Claude and Codex behavior aligned across `claude/`, `codex/`, `codex/.agents/skills/`, installers, uninstallers, and the README.
- Treat `claude/agents/`, `claude/commands/`, and `claude/memory/` as upstream inputs when porting workflows into Codex guidance or skills.
- Prefer editing the checked-in source files in this repository instead of patching installed files under a home directory.
- Validate both installation targets whenever the Codex setup changes: `~/.codex` for global guidance/config and `~/.codex/skills` for user skills.
- Keep `install.ps1` and `install.sh` feature-equivalent. Keep `uninstall.ps1` and `uninstall.sh` feature-equivalent as well.
- When installer behavior changes, update the README in the same change so the documented layout matches what is installed.
- For reviews in this repository, check for portability issues across PowerShell, POSIX shell, path handling, backup behavior, and recursive copy semantics.
