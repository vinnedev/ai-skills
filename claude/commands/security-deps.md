Audit dependencies for known vulnerabilities and supply chain risks.

SCOPE: $ARGUMENTS

Step 1 — Run package manager audit:
- Node.js: `npm audit --json` or `pnpm audit --json`
- Go: `go list -m -json all` + check against known CVE databases
- Python: `pip-audit` or `safety check`

Step 2 — Analyze findings:
- Severity classification (critical, high, moderate, low)
- Exploitability in context of this project
- Whether the vulnerable code path is actually used
- Available fixes (patch version, alternative package)

Step 3 — Supply chain risks:
- Check for dependency confusion (private package names that could be claimed on public registries)
- Check for typosquatting (package names similar to popular packages)
- Verify lock file integrity
- Check for post-install scripts in dependencies that execute arbitrary code
- Identify abandoned/unmaintained dependencies (no updates in 2+ years)
- Check for packages with excessive permissions (filesystem, network, child_process)

Step 4 — Report:
For each vulnerable dependency:
```
[SEVERITY] package@version
→ CVE: CVE-XXXX-XXXXX
→ Vulnerable path: how this project uses it
→ Impact: what an attacker can achieve
→ Fix: upgrade to version X.Y.Z or replace with alternative
```

End with:
- Total vulnerabilities by severity
- Immediate actions required
- Dependency health score