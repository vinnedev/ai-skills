#!/usr/bin/env python3
"""
Multi-agent orchestrator using Claude Code SDK.

Usage:
  python3 ~/.claude/scripts/orchestrate.py --pipeline feature --prompt "Add rate limiting to API"
  python3 ~/.claude/scripts/orchestrate.py --pipeline review --path ./src
  python3 ~/.claude/scripts/orchestrate.py --pipeline perf --path ./src/services
  python3 ~/.claude/scripts/orchestrate.py --pipeline refactor --prompt "Extract auth module"
  python3 ~/.claude/scripts/orchestrate.py --pipeline new-service --prompt "Notification service"
  python3 ~/.claude/scripts/orchestrate.py --pipeline security --path ./src
  python3 ~/.claude/scripts/orchestrate.py --pipeline security-fix --path ./src
  python3 ~/.claude/scripts/orchestrate.py --pipeline security-headers --path ./src
  python3 ~/.claude/scripts/orchestrate.py --pipeline security-deps --path .
  python3 ~/.claude/scripts/orchestrate.py --pipeline security-auth --path ./src
  python3 ~/.claude/scripts/orchestrate.py --parallel "Generate user service" "Generate auth service"
  python3 ~/.claude/scripts/orchestrate.py --model sonnet --pipeline feature --prompt "Add caching"
"""

import argparse
import asyncio
import os
import sys
import time

from claude_code_sdk import query
from claude_code_sdk.types import ClaudeCodeOptions


PIPELINES = {
    "feature": [
        {"role": "explore", "prompt": "Analyze the codebase and identify existing patterns, architecture, and conventions relevant to: {prompt}", "parallel_group": None},
        {"role": "architect", "prompt": "Based on the codebase analysis, implement the following feature following enterprise patterns: {prompt}", "parallel_group": None},
        {"role": "review", "prompt": "Review all changes made in this session for security, performance, and architectural issues. Output findings in structured format.", "parallel_group": None},
    ],
    "review": [
        {"role": "review", "prompt": "Perform a comprehensive code review of {path}. Check security, performance, SOLID compliance, error handling, and scalability.", "parallel_group": "audit"},
        {"role": "perf", "prompt": "Audit {path} for performance bottlenecks, algorithmic complexity issues, and optimization opportunities.", "parallel_group": "audit"},
    ],
    "perf": [
        {"role": "perf", "prompt": "Deep performance audit of {path}. Analyze algorithmic complexity, database queries, memory usage, I/O patterns, and caching opportunities.", "parallel_group": None},
    ],
    "refactor": [
        {"role": "explore", "prompt": "Map all files, dependencies, and usages related to: {prompt}", "parallel_group": None},
        {"role": "architect", "prompt": "Refactor the following, maintaining backward compatibility: {prompt}", "parallel_group": None},
        {"role": "review", "prompt": "Review the refactoring for breaking changes, regressions, and pattern consistency.", "parallel_group": None},
    ],
    "new-service": [
        {"role": "architect", "prompt": "Design and scaffold a new microservice: {prompt}. Include domain, infrastructure, interfaces layers, health check, graceful shutdown, and tests.", "parallel_group": None},
        {"role": "review", "prompt": "Review the new service for enterprise standards compliance.", "parallel_group": "validate"},
        {"role": "perf", "prompt": "Audit the new service architecture for scalability and performance patterns.", "parallel_group": "validate"},
    ],
    "security": [
        {"role": "explore", "prompt": "Map the attack surface of {path}: all entry points (API routes, forms, WebSocket handlers, IPC bridges), authentication flows, file upload handlers, and dependencies.", "parallel_group": None},
        {"role": "security", "prompt": "Perform a comprehensive security audit of {path}. Cover ALL vulnerability categories: OWASP Top 10, API vulnerabilities (IDOR/BOLA/BFLA/mass assignment), injection (SQL/NoSQL/Command/Template), XSS (stored/reflected/DOM), CSRF, file upload attacks, auth/session/token weaknesses, business logic flaws, cryptography issues, infrastructure misconfigs, header security, and supply chain risks. For each finding provide: [SEVERITY] [CATEGORY] file:line → Vulnerability → Impact → PoC → Fix.", "parallel_group": None},
        {"role": "security", "prompt": "Analyze vulnerability chains in {path}: identify how individual findings can be combined for higher impact (e.g., XSS + cookie theft = session hijacking, IDOR + data leak = account takeover). Provide step-by-step exploitation paths.", "parallel_group": None},
    ],
    "security-fix": [
        {"role": "security", "prompt": "Scan {path} for CRITICAL and HIGH severity vulnerabilities. Focus on: RCE, injection, auth bypass, secret exposure, IDOR, XSS, SSRF. Provide exact file:line locations and specific fix instructions.", "parallel_group": None},
        {"role": "architect", "prompt": "Fix all CRITICAL and HIGH security vulnerabilities identified in {path}. Apply fixes in order of severity. Each fix must be minimal and targeted.", "parallel_group": None},
        {"role": "security", "prompt": "Re-scan {path} to verify all CRITICAL and HIGH vulnerabilities have been remediated. Report any remaining issues.", "parallel_group": None},
    ],
    "security-headers": [
        {"role": "security", "prompt": "Audit HTTP security headers and browser security configuration in {path}. Check: CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, COOP, CORP, COEP, cookie attributes (HttpOnly/Secure/SameSite), CORS config, mixed content. Provide exact configuration fixes for the detected framework.", "parallel_group": None},
    ],
    "security-deps": [
        {"role": "security", "prompt": "Audit all dependencies in {path} for: known CVEs (run npm audit or equivalent), dependency confusion risks, typosquatting, abandoned packages, post-install scripts, lock file integrity. For each vulnerable dep: [SEVERITY] package@version → CVE → Impact → Fix.", "parallel_group": None},
    ],
    "security-auth": [
        {"role": "security", "prompt": "Deep audit of authentication, session management, and token handling in {path}. Check: password storage (hashing algo, salt, iterations), JWT implementation (exp/aud/iss/alg validation, secret strength), session lifecycle (creation/validation/expiry/invalidation), OAuth/SSO implementation, MFA, account lockout, brute force protection, credential stuffing defense, session fixation/hijacking, token reuse after logout.", "parallel_group": None},
    ],
}

ROLE_CONFIG = {
    "explore": {
        "system": "You are a codebase explorer. Search thoroughly and report findings concisely. Focus on patterns, conventions, and architecture.",
        "model": "haiku",
        "tools": ["Read", "Glob", "Grep", "Bash(find:*)", "Bash(wc:*)"],
        "max_turns": 15,
    },
    "architect": {
        "system": "You are an enterprise code architect following Netflix/Uber/Apple standards. Deliver production-ready code only. No comments, no explanations unless requested. Follow SOLID, Clean Code, early returns, lookup tables.",
        "model": "sonnet",
        "tools": ["Read", "Glob", "Grep", "Edit", "Write", "Bash(npx tsc:*)", "Bash(npm run:*)", "Bash(go build:*)", "Bash(go vet:*)"],
        "max_turns": 30,
    },
    "review": {
        "system": "You are a senior staff engineer performing code review. Report findings by severity: CRITICAL > HIGH > MEDIUM > LOW. Check security, performance, SOLID, error handling. End with APPROVE / REQUEST CHANGES / BLOCK.",
        "model": "sonnet",
        "tools": ["Read", "Glob", "Grep"],
        "max_turns": 20,
    },
    "perf": {
        "system": "You are a performance engineer. Identify bottlenecks and provide concrete optimization strategies. Report: [IMPACT: H/M/L] [EFFORT: L/M/H] file:line → Issue → Fix → Estimated gain.",
        "model": "sonnet",
        "tools": ["Read", "Glob", "Grep", "Bash(npx tsc:*)", "Bash(go test -bench:*)"],
        "max_turns": 20,
    },
    "security": {
        "system": "You are an elite cybersecurity engineer and bug bounty hunter (Google Project Zero, HackerOne top researcher level). Identify every exploitable vulnerability with surgical precision. Cover: OWASP Top 10, API security (IDOR/BOLA/BFLA/mass assignment), injection (SQL/NoSQL/Command/Template/LDAP/XPath), XSS (stored/reflected/DOM), CSRF, file upload attacks (web shell/ZIP Slip/polyglot/path traversal), auth/session/token (JWT/OAuth/MFA bypass), business logic flaws (payment bypass/race condition/privilege escalation), cryptography (weak hashing/hardcoded keys/predictable RNG), infrastructure (Docker/K8s/exposed services/CI-CD leaks), desktop/Electron/Wails (IPC bridge/DevTools/auto-update MITM), headers (CSP/HSTS/CORS), logging (PII in logs/no audit trail), supply chain (dependency confusion/typosquatting). Report format: [SEVERITY: CRITICAL|HIGH|MEDIUM|LOW|INFO] [CATEGORY] file:line → Vulnerability (CWE) → Impact → PoC → Fix. Always read source code before reporting. Never report theoretical issues without evidence. Chain vulnerabilities for maximum impact demonstration.",
        "model": "opus",
        "tools": ["Read", "Glob", "Grep", "Bash(npm audit:*)", "Bash(go list:*)", "Bash(git log:*)", "Bash(git diff:*)", "Bash(curl -s:*)"],
        "max_turns": 40,
    },
}


async def run_agent(role: str, prompt: str, cwd: str, model_override: str | None = None) -> tuple[str, float]:
    config = ROLE_CONFIG[role]
    model = model_override or config["model"]

    options = ClaudeCodeOptions(
        system_prompt=config["system"],
        model=model,
        allowed_tools=config["tools"],
        max_turns=config["max_turns"],
        permission_mode="bypassPermissions",
        cwd=cwd,
    )

    result_parts = []
    start = time.time()

    async for event in query(prompt=prompt, options=options):
        if hasattr(event, "content"):
            for block in event.content:
                if hasattr(block, "text"):
                    result_parts.append(block.text)

    elapsed = time.time() - start
    return "\n".join(result_parts), elapsed


async def run_step_group(steps: list[dict], prompt: str, path: str, cwd: str, model_override: str | None) -> list[tuple[str, str, float]]:
    tasks = []
    for step in steps:
        step_prompt = step["prompt"].format(prompt=prompt, path=path)
        tasks.append(run_agent(step["role"], step_prompt, cwd, model_override))

    results = await asyncio.gather(*tasks, return_exceptions=True)
    output = []
    for step, result in zip(steps, results):
        if isinstance(result, Exception):
            output.append((step["role"], f"ERROR: {result}", 0.0))
        else:
            text, elapsed = result
            output.append((step["role"], text, elapsed))
    return output


async def run_pipeline(pipeline_name: str, prompt: str, path: str, cwd: str, model_override: str | None):
    steps = PIPELINES.get(pipeline_name)
    if not steps:
        print(f"Unknown pipeline: {pipeline_name}")
        print(f"Available: {', '.join(PIPELINES.keys())}")
        sys.exit(1)

    groups: list[list[dict]] = []
    current_group: list[dict] = []
    current_parallel_key = None

    for step in steps:
        pg = step["parallel_group"]
        if pg is None:
            if current_group:
                groups.append(current_group)
                current_group = []
            groups.append([step])
            current_parallel_key = None
        elif pg == current_parallel_key:
            current_group.append(step)
        else:
            if current_group:
                groups.append(current_group)
            current_group = [step]
            current_parallel_key = pg

    if current_group:
        groups.append(current_group)

    total_steps = len(steps)
    step_num = 0

    print(f"\n{'='*60}")
    print(f"  Pipeline: {pipeline_name} | {total_steps} steps | cwd: {cwd}")
    print(f"{'='*60}")

    pipeline_start = time.time()

    for group in groups:
        is_parallel = len(group) > 1
        if is_parallel:
            roles = ", ".join(s["role"].upper() for s in group)
            print(f"\n  [PARALLEL] {roles}")

        results = await run_step_group(group, prompt, path, cwd, model_override)

        for role, text, elapsed in results:
            step_num += 1
            print(f"\n  [{step_num}/{total_steps}] {role.upper()} ({elapsed:.1f}s)")
            print(f"  {'-'*56}")
            for line in text.split("\n"):
                print(f"  {line}")

    total_time = time.time() - pipeline_start
    print(f"\n{'='*60}")
    print(f"  Pipeline complete in {total_time:.1f}s")
    print(f"{'='*60}\n")


async def run_parallel(prompts: list[str], cwd: str, model_override: str | None):
    print(f"\n{'='*60}")
    print(f"  Parallel execution: {len(prompts)} agents")
    print(f"{'='*60}")

    start = time.time()
    tasks = [run_agent("architect", p, cwd, model_override) for p in prompts]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    for i, (prompt_text, result) in enumerate(zip(prompts, results), 1):
        if isinstance(result, Exception):
            print(f"\n  [Agent {i}] {prompt_text[:60]}")
            print(f"  ERROR: {result}")
        else:
            text, elapsed = result
            print(f"\n  [Agent {i}] {prompt_text[:60]} ({elapsed:.1f}s)")
            print(f"  {'-'*56}")
            for line in text.split("\n"):
                print(f"  {line}")

    total = time.time() - start
    print(f"\n{'='*60}")
    print(f"  All agents complete in {total:.1f}s")
    print(f"{'='*60}\n")


def main():
    parser = argparse.ArgumentParser(description="Claude Code Multi-Agent Orchestrator")
    parser.add_argument("--pipeline", choices=list(PIPELINES.keys()), help="Pipeline to run")
    parser.add_argument("--prompt", default="", help="Task description")
    parser.add_argument("--path", default="./src", help="Path to analyze")
    parser.add_argument("--cwd", default=os.getcwd(), help="Working directory")
    parser.add_argument("--model", default=None, help="Override model for all agents (haiku, sonnet, opus)")
    parser.add_argument("--parallel", nargs="+", help="Run multiple prompts in parallel")

    args = parser.parse_args()

    if args.parallel:
        asyncio.run(run_parallel(args.parallel, args.cwd, args.model))
    elif args.pipeline:
        if not args.prompt and args.pipeline not in ("review", "perf"):
            print("ERROR: --prompt is required for this pipeline")
            sys.exit(1)
        asyncio.run(run_pipeline(args.pipeline, args.prompt, args.path, args.cwd, args.model))
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
