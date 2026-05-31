# Phase 6: Security and Access

Status: Not started

## Goal

Make access safe and manageable without making the homelab workflow painful.

## Current state

Postgres authentication in `postgres.nix`:

```text
local all all trust
host all all 192.168.1.1/24 scram-sha-256
host all all 172.25.0.0/16 scram-sha-256
```

pgweb is exposed through nginx at:

```text
pgweb.cosmos.cboxlab.com
```

Secrets are stored in files under `nixos-images/postgres/secrets/`, likely protected by existing repo secret handling.

## Areas to improve

### Database access

- Prefer per-app users only.
- Optional readonly users: `app_ro`.
- Password rotation workflow.
- Avoid shared admin credentials in app configs.
- Review whether `local trust` is still acceptable.

### pgweb access

pgweb is useful but powerful. Consider protecting it with one of:

- LAN-only access
- Tailscale-only access
- HTTP basic auth
- Cloudflare Access
- VPN-only DNS

### Transport security

For LAN-only use, plaintext may be acceptable. For future cross-network access, consider:

- Postgres TLS
- Tailscale path
- SSH tunnel for admin operations

## Deliverables

- [ ] Decide how app DB passwords are generated and stored.
- [ ] Add password rotation runbook or command.
- [ ] Decide whether readonly users should be standard.
- [ ] Review `local trust` and document why it is accepted or change it.
- [ ] Protect pgweb with an explicit access policy.
- [ ] Document admin access path.

## Validation

- A compromised app credential only affects that app database.
- pgweb is not accidentally available to unintended users.
- Credential rotation is possible without inventing a process during an incident.
