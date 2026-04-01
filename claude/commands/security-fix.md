Fix security vulnerabilities identified in the codebase.

TARGET: $ARGUMENTS

If a specific vulnerability or file is provided, fix only that. Otherwise, fix all findings from the most recent security audit, starting with CRITICAL severity.

RULES:
- Fix vulnerabilities in order: CRITICAL → HIGH → MEDIUM → LOW
- Each fix must be minimal and targeted — do not refactor unrelated code
- Ensure fixes don't break existing functionality
- Run tests after each fix if available
- For each fix, explain what was vulnerable and what the fix does (one line)

COMMON FIXES TO APPLY:

Auth/Session:
- Replace plain text passwords with argon2/bcrypt hashing
- Add JWT expiration, audience, and issuer validation
- Add rate limiting to login/register/reset endpoints
- Implement account lockout after N failed attempts
- Add CSRF tokens to state-changing operations
- Set HttpOnly, Secure, SameSite on all cookies

Injection:
- Parameterize all database queries
- Escape/sanitize all user input before rendering
- Use allowlists for command arguments
- Use template engines with auto-escaping

Headers:
- Add security headers middleware (CSP, HSTS, X-Frame-Options, etc.)
- Configure CORS with specific origins (not wildcard)

File Upload:
- Validate file type by magic bytes (not just extension/MIME)
- Enforce size limits
- Generate random filenames
- Store uploads outside webroot

Infrastructure:
- Remove .env from git, add to .gitignore
- Remove exposed debug endpoints
- Disable stack traces in production
- Remove server version headers

After all fixes, run the security-audit skill again to verify remediation.