When performing security analysis, bug bounty, or vulnerability assessment, follow this comprehensive methodology.

SEVERITY CLASSIFICATION:
- CRITICAL: RCE, SQL injection, auth bypass, full data breach, account takeover
- HIGH: Stored XSS, SSRF, IDOR with sensitive data, privilege escalation, secret exposure
- MEDIUM: CSRF, information disclosure, missing security headers, weak crypto
- LOW: Verbose errors, version disclosure, missing best practices
- INFO: Hardening recommendations

VULNERABILITY CHECKLIST — scan for ALL of these:

WEB / APP BASIC:
- Plain text passwords, no auth on API, admin exposed, .env in git
- Public DB backups, directory listing, incremental IDs, predictable UUIDs, logs exposing tokens
- JWT without expiration/signature, CORS *, no HTTPS, no input validation
- Stack trace exposed, server version exposed, no rate limiting
- File upload without validation, default credentials, predictable tokens
- Cookies without HttpOnly/Secure/SameSite, session ID in URL
- API over-fetching, frontend-only permission validation

OWASP TOP 10:
- Broken Access Control, Cryptographic Failures, Injection (SQL/NoSQL/Command/LDAP/XPath/Template)
- Insecure Design, Security Misconfiguration, Vulnerable Components
- Authentication Failures, Software Integrity Failures, Logging Failures, SSRF
- Stored XSS, Reflected XSS, DOM XSS, CSRF
- Session fixation, session hijacking, sensitive data exposure
- Insecure deserialization, insufficient logging/monitoring

API:
- IDOR, BOLA, BFLA, mass assignment, missing rate limit, user enumeration
- Token reuse, infinite refresh token, JWT alg none, weak JWT secret
- API key in frontend, webhook without signature/replay protection
- Pagination abuse, GraphQL introspection/batching/depth attacks

FILE UPLOAD:
- Web shell, HTML/SVG/PDF with JS, path traversal, ZIP Slip
- ImageTragick, polyglot files, MIME/extension spoofing, archive bomb
- Large file DoS, file overwriting, symlink upload, executable upload
- Malware upload, .exe/.js/.php allowed extensions

DATABASE:
- SQL/NoSQL injection (union, blind, error-based, time-based, out-of-band)
- Exposed DB ports, public backups, timing attack login, error-based enumeration
- Weak password hashing (MD5/SHA1), no encryption at rest, shared DB credentials
- Dump exposed, no network segmentation for DB access

INFRASTRUCTURE:
- Docker as root, secrets in env/logs, public S3/cloud storage
- MongoDB/Redis/Elasticsearch exposed, K8s dashboard public, SSH password auth
- .git exposed, .DS_Store, backup.zip, old site folders, dev/staging exposed
- CI/CD token leaks, build artifacts exposed, open ports, no firewall, no network segmentation

ADVANCED:
- SSRF, RCE, LFI, RFI, deserialization RCE, race condition (TOCTOU)
- Cache poisoning, HTTP smuggling, response splitting, prototype pollution
- Sandbox escape, memory corruption, buffer overflow, timing/side-channel attacks
- Clickjacking, tabnabbing, DNS rebinding, subdomain takeover
- Supply chain (dependency confusion, typosquatting, build pipeline)
- OAuth misconfig, SSO takeover, MFA bypass, replay attack
- WebSocket hijacking, CSP bypass, service worker attack, WASM escape
- Spectre/Meltdown exposure via shared infrastructure

DESKTOP / WAILS / ELECTRON:
- Exposed JS→Go bridge, filesystem access without validation
- Local path traversal, command execution via bridge
- Opening external URLs unsafely, loading external content without validation
- DevTools in production, local DB exposure, plaintext tokens/sessions stored locally
- Auto-update MITM, DLL hijacking, env var exposure
- Debug mode, sensitive logs/crash dumps, file:// protocol abuse
- IPC without validation, shell execution, arbitrary file read/write
- Local privilege escalation

BUSINESS LOGIC:
- Negative price, coupon abuse, payment bypass, double spend
- Race condition on balance, trial reset, role escalation
- Password reset abuse, email verification bypass, multi-tenant leak
- Unauthorized download, predictable links, unlimited resource creation
- Storage/email/referral/points abuse, inventory/order manipulation
- Subscription/license bypass

AUTH / SESSION / TOKEN:
- Weak password policy, no lockout, brute force, credential stuffing
- Session fixation/hijacking, token reuse, long-lived tokens
- JWT without exp/aud/iss, refresh token reuse, logout not invalidating
- Multiple sessions not tracked, missing device/session management, missing MFA, MFA bypass
- OAuth misconfig, open redirect in OAuth, account takeover via reset

HEADERS:
- Missing CSP, X-Frame-Options, HSTS, X-Content-Type-Options
- Missing Referrer-Policy, Permissions-Policy
- Insecure cookies, mixed content, CORS misconfiguration, clickjacking

LOGGING:
- No audit logs, passwords/tokens in logs, no intrusion/anomaly detection
- No alerting, logs public, no rotation, no tamper protection, log injection

CRYPTOGRAPHY:
- Weak hashing (MD5/SHA1), custom crypto, hardcoded keys, static IV
- No encryption at rest/transit, predictable RNG, insecure token generation
- ECB mode, key reuse across environments

SUPPLY CHAIN:
- Auto-update without signature, update over HTTP
- Dependency confusion, malicious package injection, build pipeline compromise
- CI/CD secrets exposed, binary replacement, DLL hijacking, plugin execution without validation

OUTPUT FORMAT for each finding:
[SEVERITY] [CATEGORY] file:line
→ Vulnerability: name (CWE-XXX)
→ Impact: what attacker achieves
→ PoC: reproduction steps or payload
→ Fix: specific code change