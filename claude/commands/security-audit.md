Perform a comprehensive security audit on the current codebase following bug bounty methodology.

SCOPE: $ARGUMENTS

If no scope is specified, audit the entire project in the current working directory.

EXECUTION PLAN:

Step 1 — RECONNAISSANCE
Explore the codebase to map the attack surface:
- Identify all entry points (API routes, forms, WebSocket handlers, IPC bridges, GraphQL)
- Enumerate technologies, frameworks, and dependencies
- Find configuration files (.env, config, secrets, docker-compose)
- Map authentication and authorization flows (JWT, OAuth, SSO, MFA, session)
- Check for exposed assets (.git, backups, debug endpoints, .DS_Store, backup.zip)
- Identify file upload handlers, cron jobs, webhooks, admin panels

Step 2 — DEPENDENCY AUDIT
Check for vulnerable dependencies:
- Run `npm audit` or `go mod verify` or equivalent
- Cross-reference dependency versions against known CVEs
- Check for dependency confusion risks (private package names on public registries)
- Look for typosquatting in dependency names
- Identify abandoned packages (no updates 2+ years)
- Check for post-install scripts executing arbitrary code
- Verify lock file integrity

Step 3 — STATIC ANALYSIS
Review source code for ALL of these vulnerability categories:

A) WEB / APP BASIC:
- Plain text passwords in storage or transit
- No authentication on API endpoints
- Admin endpoints exposed without auth
- .env / config files in git or publicly accessible
- Public database backups or dumps
- Public uploads with directory listing
- Sequential/incremental IDs enabling enumeration
- Predictable UUIDs (v1 timestamp-based)
- Logs exposing tokens, passwords, PII
- JWT without expiration, signature, aud, or iss validation
- CORS wildcard (*) or credentials with wildcard
- No HTTPS / mixed content
- No input validation or sanitization
- Stack traces in production responses
- Server version headers exposed
- No rate limiting on sensitive endpoints
- File upload without type/size/extension validation
- Allowing dangerous extensions (.exe, .js, .php, .jsp, .aspx)
- Default or weak credentials
- Password reset without secure token
- Predictable session tokens
- Cookies without HttpOnly/Secure/SameSite
- Session ID in URL parameters
- API over-fetching (excessive data return)
- Frontend-only permission validation

B) OWASP TOP 10:
- A01 Broken Access Control — missing authz, IDOR, privilege escalation
- A02 Cryptographic Failures — weak hashing, no encryption, hardcoded keys
- A03 Injection — SQL, NoSQL, Command, LDAP, XPath, Template, Header injection
- A04 Insecure Design — no threat model, no defense in depth
- A05 Security Misconfiguration — default creds, verbose errors, debug mode
- A06 Vulnerable Components — outdated deps with known CVEs
- A07 Authentication Failures — session fixation, session hijacking, brute force, credential stuffing
- A08 Software Integrity Failures — insecure deserialization, unsigned updates
- A09 Security Logging Failures — no audit trail, log injection, passwords in logs
- A10 SSRF — internal service access, cloud metadata (169.254.169.254), port scan
- Stored XSS, Reflected XSS, DOM XSS
- CSRF on state-changing operations
- Sensitive data exposure

C) API:
- IDOR / BOLA (Broken Object Level Authorization)
- BFLA (Broken Function Level Authorization)
- Mass assignment / auto-binding
- Missing rate limit on auth/search/export endpoints
- User enumeration via error messages or timing differences
- Token reuse after logout/revocation
- Infinite refresh token lifetime
- JWT alg:none attack
- Weak JWT signing secret (brute-forceable)
- API keys exposed in frontend code or URLs
- Webhooks without signature verification or replay protection
- Pagination abuse (fetching all records)
- GraphQL introspection enabled in production
- GraphQL batching and depth/complexity attacks

D) File Upload:
- Web shell upload (.php, .jsp, .aspx, .py)
- HTML/SVG/PDF with embedded JavaScript
- Path traversal via filename (../../etc/passwd)
- ZIP Slip (archive with path traversal entries)
- ImageTragick (ImageMagick CVE-2016-3714)
- Polyglot files (valid as multiple types)
- Malware upload (no AV scanning)
- Large file DoS (no size limit)
- MIME type spoofing
- Extension spoofing (double extension, null byte)
- File overwriting (no unique naming)
- Symlink upload (reading arbitrary files)
- Archive bomb (zip bomb, decompression DoS)
- Executable file upload

E) Database:
- SQL Injection (union, blind, error-based, time-based, out-of-band)
- NoSQL Injection (MongoDB operator: $gt, $ne, $regex, $where)
- ORM injection via raw query construction
- Exposed database ports (3306, 5432, 27017, 6379, 9200)
- Public backups or dumps
- Timing attack on login
- Error-based enumeration (different errors for valid vs invalid records)
- Weak password hashing (MD5, SHA1, no salt)
- No encryption at rest
- Shared or default database credentials

F) Infrastructure / DevOps:
- Docker containers running as root
- Docker socket exposed
- Secrets in environment variables without vault
- Secrets leaked in logs or error messages
- Public S3 buckets or cloud storage (check AWS/GCP/Azure configs)
- MongoDB/Redis/Elasticsearch exposed to internet
- Kubernetes dashboard publicly accessible
- SSH with password auth enabled
- Git repository exposed (/.git/)
- .DS_Store / backup.zip / old folders exposed
- Dev/staging environments exposed to public
- CI/CD token leaks in build logs
- Build artifacts publicly accessible
- Unnecessary open ports
- No firewall or WAF
- No network segmentation

G) Advanced Attacks:
- SSRF (Server-Side Request Forgery) — fetch/axios/http calls with user-controlled URLs
- RCE — eval, exec, system, child_process.exec, subprocess with user input
- LFI (Local File Inclusion) — require(), fs.readFile with user path
- RFI (Remote File Inclusion)
- Deserialization RCE (JSON.parse unsafe, pickle, Java ObjectInputStream)
- Race condition / TOCTOU (check-then-act patterns, double spend)
- Cache poisoning (X-Forwarded-Host, Host header injection)
- HTTP Request Smuggling (CL.TE, TE.CL)
- HTTP Response Splitting (header injection via CRLF)
- Prototype pollution (__proto__, constructor.prototype in JS)
- Sandbox escape (vm2, isolated-vm, WASM execution)
- Memory corruption / buffer overflow
- Timing attacks / side channel attacks
- Clickjacking (missing X-Frame-Options/CSP frame-ancestors)
- Tabnabbing (target="_blank" without rel="noopener noreferrer")
- DNS Rebinding
- Subdomain takeover (dangling CNAME/A records)
- OAuth misconfiguration (open redirect, missing state/PKCE)
- SSO takeover (SAML signature bypass)
- MFA bypass (backup codes, race condition, session persistence after MFA)
- Replay attack (no nonce or timestamp)
- WebSocket hijacking (CSWSH, missing origin check)
- CSP bypass (unsafe-inline, unsafe-eval, base-uri missing, data: URI)
- Service Worker persistent XSS
- WASM sandbox escape
- Supply chain (dependency confusion, typosquatting, build pipeline compromise)

H) Desktop / Wails / Electron (if applicable):
- Exposed JS → Go/Native bridge functions callable from renderer
- Filesystem access without path validation or sandboxing
- Local path traversal via bridge API
- Command execution via IPC bridge
- Opening external URLs without sanitization (nodeIntegration risks)
- Loading remote/external content in webview without restrictions
- DevTools enabled in production builds
- Local database/SQLite exposure without encryption
- Tokens or sessions stored in plaintext (localStorage, files)
- Auto-update without code signature verification (MITM)
- DLL/dylib hijacking
- Environment variable exposure to renderer process
- Debug mode enabled in production
- Logs or crash dumps containing sensitive data
- file:// protocol abuse
- IPC messages without validation or sanitization
- Shell command execution from renderer
- Arbitrary file read/write via bridge
- Local privilege escalation

I) Business Logic:
- Negative price or quantity in purchases
- Coupon/promo code abuse (unlimited reuse, stacking)
- Payment bypass (modifying client-side total, skipping payment step)
- Double spend (race condition on balance/credits)
- Trial reset abuse (new account creation, timestamp manipulation)
- Role/privilege escalation via parameter tampering
- Password reset abuse (token reuse, no expiry, email enumeration)
- Email verification bypass
- Multi-tenant data leakage (missing tenant_id isolation)
- Unauthorized file download or export
- Predictable private share links
- Unlimited resource creation (DoS via business logic)
- Storage/email/referral/points/rewards abuse
- Inventory manipulation (holding without purchasing)
- Order status manipulation
- Subscription or license bypass

J) Auth / Session / Token:
- Weak password policy (no minimum length or complexity)
- No account lockout after failed attempts
- Brute force or credential stuffing (no rate limit, no CAPTCHA)
- Session fixation (pre-auth session ID accepted post-auth)
- Session hijacking (token leakage via XSS, logs, URL)
- Token reuse after logout or revocation
- Long-lived access tokens without rotation
- JWT without exp, aud, iss claims
- Refresh token reuse (no rotation policy)
- Logout not invalidating server-side session
- Multiple sessions not tracked or manageable
- Missing device/session management UI
- Missing MFA
- MFA bypass via backup codes, race condition, or persistent session
- OAuth: missing state parameter, missing PKCE, open redirect in redirect_uri
- Account takeover via password reset (weak token, timing, no expiry)

K) Headers / Browser Security:
- Missing Content-Security-Policy or weak policy (unsafe-inline, unsafe-eval)
- Missing X-Frame-Options or CSP frame-ancestors
- Missing Strict-Transport-Security (HSTS)
- Missing X-Content-Type-Options: nosniff
- Missing Referrer-Policy
- Missing Permissions-Policy
- Missing COOP / CORP / COEP headers
- Insecure cookie attributes
- Mixed content (HTTP resources on HTTPS page)
- CORS misconfiguration (wildcard, credentials with wildcard)

L) Logging / Monitoring:
- No audit logs for sensitive operations (login, permission changes, data export)
- Logs containing passwords, tokens, or PII
- No intrusion detection or anomaly detection
- No alerting on security events (multiple failed logins, unusual access patterns)
- Logs publicly accessible
- No log rotation (disk exhaustion risk)
- No tamper protection on logs
- Log injection (CRLF or newline injection in log entries)

M) Cryptography:
- Weak hashing (MD5, SHA1 for passwords without salt)
- Custom or homegrown cryptography
- Hardcoded encryption keys in source code
- Static IV (same IV reused across encryptions)
- No encryption at rest for sensitive data
- No encryption in transit (no TLS, or TLS < 1.2)
- Predictable random number generator (Math.random() for security tokens)
- Insecure token generation (sequential, timestamp-based, short entropy)
- ECB mode encryption
- Key reuse across environments (same key in dev and prod)

N) Supply Chain:
- Auto-update without code signing verification
- Updates downloaded over HTTP
- Dependency confusion (private package name claimable on public registry)
- Malicious package injection via compromised dependency
- Build pipeline compromise (CI/CD script injection, poisoned cache)
- CI/CD secrets exposed in logs or artifacts
- Binary replacement attack
- DLL/dylib hijacking via PATH manipulation
- Plugin or extension execution without validation or sandboxing
- Lock file manipulation or missing lock file

Step 4 — VULNERABILITY CHAIN ANALYSIS
Identify how individual findings can be chained:
- XSS + cookie theft = session hijacking
- IDOR + data exposure = account takeover
- SSRF + cloud metadata = credential theft → RCE
- File upload + path traversal = RCE
- Mass assignment + BFLA = privilege escalation
- Race condition + double spend = financial fraud
- Log injection + SIEM alert = detection evasion

Step 5 — REPORT
Generate structured report using the security-auditor agent:

```
[SEVERITY: CRITICAL|HIGH|MEDIUM|LOW|INFO] [CATEGORY] file:line
→ Vulnerability: name (CWE-XXX)
→ Description: what is vulnerable and why
→ Impact: what an attacker achieves
→ Proof of Concept: exact steps or payload
→ Remediation: specific code fix or configuration change
→ References: OWASP, CWE, CVE links
```

Report structure:
1. Executive Summary — total findings by severity, top 3 risks, overall risk rating
2. Attack Surface Map — entry points, technologies, auth mechanisms
3. Findings — grouped by category, sorted by severity
4. Vulnerability Chain Analysis — chained attack scenarios
5. Remediation Priority Matrix — quick wins vs strategic fixes
6. Compliance Gaps — OWASP Top 10 coverage

Use the security-auditor agent for the analysis. Delegate to code-reviewer for non-security code quality issues found during the audit.
