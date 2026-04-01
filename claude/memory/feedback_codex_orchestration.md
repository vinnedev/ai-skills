---
name: Codex orchestration preference
description: User wants Claude to proactively orchestrate Codex for complex, multi-file, or parallelizable tasks — not just when stuck
type: feedback
---

Use Codex (mcp__codex__codex) proactively and freely whenever it adds value. Do not wait for explicit instruction.

**Why:** User confirmed they liked the collaborative Claude + Codex workflow on the redis-stream-go project ("gostei do trabalho atual que ele fez em conjunto com codex").

**How to apply:**
- Large JSON/config generation (dashboards, manifests, schemas) → delegate to Codex
- Multi-file refactors that touch 3+ files → delegate or parallelize via Codex
- Tasks that can run independently in parallel → launch multiple Codex sessions (one at a time per CODEX MCP GOVERNANCE)
- Boilerplate-heavy code (tests, CRUD, provisioning configs) → Codex
- When research + implementation need to happen simultaneously → Codex handles implementation while Claude researches, or vice versa
- Always review Codex output before delivering to the user
- Codex writes files; Claude reviews and fixes edge cases (compilation errors, missing imports, type issues, etc.)
