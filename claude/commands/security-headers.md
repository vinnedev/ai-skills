Audit HTTP security headers and browser security configuration in the current codebase.

SCOPE: $ARGUMENTS

Check for:
- Content-Security-Policy (CSP) — presence, strength, bypass vectors (unsafe-inline, unsafe-eval, data:, blob:)
- Strict-Transport-Security (HSTS) — presence, max-age, includeSubDomains, preload
- X-Frame-Options — presence, value (DENY vs SAMEORIGIN)
- X-Content-Type-Options — nosniff
- Referrer-Policy — value appropriateness
- Permissions-Policy — camera, microphone, geolocation restrictions
- Cross-Origin-Opener-Policy (COOP)
- Cross-Origin-Resource-Policy (CORP)
- Cross-Origin-Embedder-Policy (COEP)
- Cookie attributes — HttpOnly, Secure, SameSite, Path, Domain
- CORS configuration — wildcard origins, credentials with wildcard, preflight caching
- Mixed content — HTTP resources loaded on HTTPS pages

Search for header configuration in:
- Server/framework middleware (Express, Fastify, Chi, Gin, etc.)
- Reverse proxy configs (nginx, Apache, Caddy)
- Helmet.js or equivalent security middleware
- Meta tags in HTML

For each missing or misconfigured header, provide the exact configuration to fix it with code examples for the detected framework.