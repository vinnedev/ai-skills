GLOBAL RULES

Before proceeding, identify the programming language in use and check available agents and always use (enterprise-code-architect.md) can be found in: ~/.claude/agents
If it's Golang, follow the instructions in ~/.claude/GO.md.
If it's TypeScript (Frontend, Backend, or Fullstack), follow the instructions in ~/.claude/TYPESCRIPT.md.
Then apply the GLOBAL RULES below.

1. Deliver only the requested output, in the exact format specified.
2. Never add explanations, comments, titles, or Markdown unless explicitly requested.
3. Never create extra files (.md, .txt, long docstrings, etc.) without direct instruction.
4. Code must always follow best practices of the language, focusing on:
   - clarity and efficiency
   - consistent, semantic naming
   - low coupling, high cohesion
   - idiomatic, modern structures
5. When ambiguity exists, prioritize conciseness and performance, never verbosity.
6. Maintain style consistency with the standard conventions of the language (PEP8, Effective Go, Airbnb JS, etc.).
7. Never repeat user instructions or generate summaries.
8. Minimize token usage — remove redundancy and unnecessary formatting.
9. When code is requested, output only raw code — nothing else.
10. When explanations are requested, provide plain, concise text — no code.
11. Always prefer early returns instead of using else statements, and always prefer hashmap/lookup tables instead of using switch cases and if-else statements in chains.
12. In existing or legacy projects, follow the current architecture and structural organization strictly to avoid regressions; do not reorganize modules, folders, or layering unless explicitly requested.

---

OUTPUT POLICY
- Code → only code (no comments).
- Text → only text (no Markdown formatting).
- Large structures → split logically, never comment.

Strict Mode: generate only code, with no text, comments, or explanations, unless explicitly requested.
Goal: deliver concise, industry-standard code — clean, direct, and production-ready.

---

ARCHITECTURE & SCALABILITY PROTOCOL

Before writing any non-trivial code (new service, module, API endpoint, or refactor), apply this checklist silently:

1. Scale: will this handle 10x current load without structural changes?
2. Boundaries: are domain boundaries clear? Does this respect separation of concerns?
3. Failure: what happens when this fails? Is there retry, fallback, or circuit breaker logic needed?
4. Idempotency: can this operation be safely retried?
5. Observability: can I trace, measure, and alert on this in production?
6. Coupling: does this create tight coupling to another service/module? If yes, introduce an interface or event.
7. Data consistency: is eventual consistency acceptable or is strong consistency required?

If any answer is unclear, ask the user before proceeding. Never assume scale requirements.

---

MICROSERVICES DESIGN PATTERNS (apply when relevant)

- Event-driven communication over synchronous calls when possible
- API-first design: define contracts before implementation
- Database-per-service: never share databases across service boundaries
- Saga pattern for distributed transactions
- CQRS when read/write patterns diverge significantly
- Strangler fig for incremental migrations
- Bulkhead isolation to prevent cascading failures
- Sidecar pattern for cross-cutting concerns (auth, logging, metrics)

---

TOKEN ECONOMY RULES

1. Never output code the user didn't request
2. Never re-read files already in context unless content may have changed
3. Use Edit over Write for modifications — diffs save tokens
4. Batch independent tool calls in parallel
5. Use targeted Grep/Glob over Agent for simple searches
6. Skip preamble, summaries, and restating the task
7. For large refactors, output only changed files — not the entire codebase
8. Prefer haiku model for subagents doing simple searches; sonnet for code generation; opus for architecture decisions

---

QUESTIONING PROTOCOL

When the user requests a new feature, service, or significant change, ask these questions ONLY if the answers are not already clear from context:

1. What is the expected throughput/load?
2. What are the latency requirements?
3. Is this a public or internal API?
4. What is the deployment target (container, serverless, edge)?
5. Are there existing patterns in the codebase to follow?

Do NOT ask all questions at once. Ask only what is missing and critical.

---

CODE REVIEW STANDARDS (apply before delivering any code)

Silently verify:
- No hardcoded secrets, URLs, or credentials
- No N+1 queries or unbounded iterations
- No unhandled promise rejections or goroutine leaks
- No race conditions in concurrent code
- Input validation at system boundaries
- Proper resource cleanup (connections, file handles, timers)
- Error propagation with context, never swallowed errors

---

CODEX MCP GOVERNANCE

The Codex MCP server runs with --dangerously-bypass-approvals-and-sandbox.
This means Codex can read/write any file and run any command without approval.

ALLOWED (deterministic, reversible):
- Pure code generation (functions, classes, modules, tests)
- File creation/editing within the project directory
- Running build tools (tsc, go build, npm run build)
- Running tests (vitest, go test, npm test)
- Code formatting (prettier, gofmt)
- Git operations (status, diff, log, add, commit)

FORBIDDEN (non-deterministic, irreversible, or security-sensitive):
- Touching .env, credentials, secrets, tokens, API keys
- Deleting files outside the project directory
- Running rm -rf, drop table, or any destructive system command
- Making network requests to external services (curl, fetch to prod APIs)
- Modifying CI/CD pipelines, Dockerfiles, or infrastructure configs
- Installing global packages or modifying system configs
- Running commands that require elevated privileges (sudo)
- Pushing to remote repositories

SAFETY RULES:
1. Always ensure git has uncommitted changes tracked before delegating to Codex
2. After Codex completes, review its output before delivering to the user
3. If Codex modifies files outside the project scope, revert immediately
4. Prefer Claude's native agents for anything touching security boundaries
5. One Codex call at a time — never parallelize multiple Codex sessions