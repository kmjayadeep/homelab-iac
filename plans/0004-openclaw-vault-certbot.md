# OpenClaw Vault-backed Certbot Plan

## Goal

Restore TLS for `openclaw.cosmos.cboxlab.com` and make future Cloudflare token
rotation automatic by having both Ansible-managed OpenClaw VMs read the existing
canonical Vault secret:

```text
homelab/kv/services/cloudflare/dns-cboxlab
property: api_token
```

Keep certificate issuance on each OpenClaw VM with Certbot and Nginx. Migrate
`openclaw` first to restore its expired certificate, then migrate
`openclaw-chinnu` before its certificate enters the renewal window. Give each VM
a separate Vault machine identity while reusing the same Cloudflare secret. Do
not create a second Cloudflare credential or copy the token into Git, Terraform,
Ansible variables, command arguments, or operator-managed password-store items.

## Current state

- The served Let's Encrypt certificate expired on 23 August 2026.
- `certbot.timer` is enabled and runs twice daily.
- Renewal fails with Cloudflare error `9109 Invalid access token` because
  `/etc/letsencrypt/cloudflare.ini` contains a stale token.
- The canonical Vault token at `services/cloudflare/dns-cboxlab` is active,
  scoped to zone read and DNS edit for `cboxlab.com`, and currently records an
  expiry date of 1 September 2027.
- `openclaw-chinnu.cosmos.cboxlab.com` currently serves a valid certificate that
  expires on 9 October 2026, but its Ansible role uses the same operator-supplied
  Cloudflare token pattern and should be migrated before renewal is due.
- Kubernetes cert-manager and external-dns already intentionally share this
  canonical identity.
- `https://vault.cosmos.cboxlab.com` is reachable from the homelab with trusted
  HTTPS. The outstanding in-cluster Vault HTTP exception must not be expanded
  to this VM.

## Design

Run Vault Agent as a system service on each OpenClaw VM. Vault Agent will:

1. authenticate through a dedicated AppRole machine identity;
2. receive a short-lived, renewable Vault token;
3. read only `services/cloudflare/dns-cboxlab`;
4. atomically render `/etc/letsencrypt/cloudflare.ini` with mode `0600`; and
5. periodically re-render the static KV secret so Vault rotations reach the VM
   without rerunning Ansible.

Certbot will continue using its existing systemd timer and DNS-Cloudflare
renewal configuration. A systemd dependency will ensure the rendered credential
file exists before Certbot runs. The existing deploy hook will reload Nginx
after successful renewal.

Each VM receives a separate AppRole (`openclaw-certbot` and
`openclaw-chinnu-certbot`) attached to the same exact-path policy, allowing one
host identity to be revoked without disrupting the other. An AppRole RoleID is
not secret. Its SecretID is a machine bootstrap credential and must exist only
in a root-owned file on that VM. Terraform must manage the auth backend, policy,
and role configuration, but must not generate or retain a SecretID in Terraform
state.

## Safety constraints

- Reuse the canonical Vault document; do not create a consumer-specific copy.
- Grant the VM an exact logical path, not a wildcard under
  `services/cloudflare/`.
- Never print or register the Cloudflare token, Vault SecretID, or rendered
  credential file in Ansible output.
- Use `no_log: true` and `diff: false` on all secret-bearing Ansible tasks.
- Bootstrap the SecretID through a non-logging stdin/file workflow; never pass
  it as a command-line argument.
- Store the Vault Agent SecretID and rendered Cloudflare file as `root:root`
  with mode `0600`.
- Connect only to `https://vault.cosmos.cboxlab.com` with certificate
  verification enabled. Do not set `tls_skip_verify` or use the internal HTTP
  endpoint.
- Do not revoke or modify the existing Cloudflare token during rollout because
  cert-manager and external-dns also consume it.
- Review the full Vault Terraform plan before apply. Terraform continues to
  manage access configuration only, never secret values.

## Phase 1: Immediate certificate recovery

Restore service before changing the authentication architecture.

- [x] Read `api_token` from the canonical Vault path into process memory using
      the authenticated operator environment; do not display or persist it
      locally.
- [x] Install the value into `/etc/letsencrypt/cloudflare.ini` over the existing
      SSH/Ansible channel with `no_log: true`, `diff: false`, and mode `0600`.
- [x] Run a forced renewal for only
      `openclaw.cosmos.cboxlab.com`; do not renew unrelated certificates.
- [x] Confirm the deploy hook reloads Nginx, or reload Nginx explicitly after a
      successful renewal.
- [x] Verify externally that the new certificate has the correct SAN, a future
      expiry date, a valid chain, and an HTTP 200 response without disabling TLS
      verification.
- [x] Leave `certbot.timer` enabled while the Vault Agent work is implemented.

## Phase 2: Vault machine identity

Add dedicated non-Kubernetes access configuration under `vault-config/`.

- [x] Enable the AppRole auth backend at `auth/approle` if it does not already
      exist. Manage the backend once and reuse it for future VM identities.
- [x] Add a policy named `openclaw-certbot` with only:

  ```hcl
  path "homelab/kv/data/services/cloudflare/dns-cboxlab" {
    capabilities = ["read"]
  }

  path "auth/token/lookup-self" {
    capabilities = ["read"]
  }
  ```

- [x] Add AppRoles named `openclaw-certbot` and
      `openclaw-chinnu-certbot`, each bound only to that policy, with no default
      policy and short-lived renewable client tokens.
- [x] Configure SecretID use and lifetime for unattended reboot recovery. Treat
      the root-owned SecretID file as the durable machine credential and rotate
      it after suspected host compromise.
- [x] Do not create an AppRole SecretID with Terraform. Generate it during the
      controlled bootstrap step so it never enters Terraform state.
- [x] Run `terraform fmt`, `terraform validate`, and a full `terraform plan` in
      `vault-config/`; verify the plan contains no KV data or secret values.
- [x] Apply only after confirming no existing Kubernetes auth roles or policies
      are replaced.

## Phase 3: Ansible and Vault Agent integration

Update `cosmos/ansible-openclaw` idempotently.

- [ ] Install a pinned Vault package from HashiCorp's authenticated package
      repository, following the host's Debian release and architecture.
- [ ] Create `/etc/vault-agent/` and `/etc/vault-agent/templates/` as
      root-owned directories.
- [ ] Install a Vault Agent configuration that:
  - uses `https://vault.cosmos.cboxlab.com` with TLS verification;
  - uses AppRole auto-auth with root-owned RoleID and SecretID files;
  - requests no policies beyond those attached to the role;
  - renders static KV secrets at a bounded interval, initially five minutes;
  - does not log rendered values; and
  - exits or retries visibly when authentication or rendering fails.
- [ ] Add a Vault Agent template for
      `/etc/letsencrypt/cloudflare.ini` that reads
      `.Data.data.api_token` from the KV v2 path and writes exactly the
      `dns_cloudflare_api_token` setting expected by Certbot.
- [ ] Manage `vault-agent.service` as enabled and running.
- [ ] Add a `certbot.service` systemd drop-in requiring and ordering after
      `vault-agent.service`. Its pre-start check must wait for a non-empty,
      root-owned credential file rather than racing the first template render.
- [ ] Parameterize the Vault AppRole name and bootstrap paths per inventory host
      so `openclaw` and `openclaw-chinnu` never share a SecretID.
- [ ] Remove the existing Ansible template task that writes the Cloudflare token
      directly from `CLOUDFLARE_API_TOKEN`; Vault Agent must be the sole writer
      after both hosts are migrated.
- [ ] Remove the `cloudflare_api_token` Ansible variable and its assertion.
      Retain the Let's Encrypt email assertion.
- [ ] Remove `CLOUDFLARE_API_TOKEN` from
      `cosmos/ansible-openclaw/.envrc` only after both hosts have completed the
      cutover, and document Vault bootstrap and runtime behavior in the README.
- [ ] Add handlers for `systemctl daemon-reload`, Vault Agent restart, and Nginx
      reload without exposing template content.
- [ ] Add an Ansible assertion or stat check for owner, mode, and non-zero size;
      never slurp or debug the credential file.

## Phase 4: Secure AppRole bootstrap and cutover

- [ ] Generate a distinct SecretID for each AppRole using an authorized Vault
      operator session. Deliver each directly into a temporary root-owned file
      on its assigned VM through a non-logging Ansible stdin/file workflow.
- [ ] Write each non-secret RoleID and secret SecretID to the host-specific paths
      referenced by Vault Agent. Ensure Ansible output is censored and temporary
      local files are removed even on failure.
- [ ] Start Vault Agent and wait for the Cloudflare credential template to be
      rendered.
- [ ] Verify the rendered file's owner, permissions, and modification time only.
      Do not read its content into terminal or Ansible output.
- [ ] Run `vault token lookup` through the agent identity or inspect Vault audit
      data to confirm the token has only `openclaw-certbot` policy access.
- [ ] Confirm an attempted read of an unrelated non-secret test path is denied;
      do not probe or print another real secret.
- [ ] Run `certbot renew --dry-run --cert-name openclaw.cosmos.cboxlab.com` and
      confirm the DNS challenge succeeds.
- [ ] Repeat the host-limited bootstrap and dry run for `openclaw-chinnu` using
      its own AppRole identity and certificate name.
- [ ] Restart each VM once during its maintenance window and verify Vault Agent
      reauthenticates, renders the file, and leaves Certbot ready for its next
      timer invocation.

## Phase 5: Rotation and failure monitoring

- [ ] Perform a rotation propagation drill without changing the production
      token: trigger a Vault Agent template refresh and verify the rendered
      file's timestamp changes while its contents remain undisclosed.
- [ ] Document the production rotation workflow:
  1. create and verify a replacement Cloudflare token;
  2. write `api_token` to the same Vault path through the approved non-logging
     workflow;
  3. update `last-rotated-at`, `expires-at`, and other required custom metadata;
  4. wait for all consumers, including OpenClaw, to reconcile;
  5. validate external-dns, cert-manager, and an OpenClaw Certbot dry run; and
  6. revoke the old token only after every consumer passes.
- [ ] Alert on `certbot.service` failure using the existing monitoring pattern or
      a systemd `OnFailure` unit.
- [ ] Add a certificate-expiry monitor that warns at least 21 days before expiry
      so a failed renewal cannot remain unnoticed.
- [ ] Monitor `vault-agent.service` availability and template age without
      exposing the rendered secret.

## Validation commands

Run commands from their component directories and keep all secret values out of
logs:

```bash
cd vault-config
terraform fmt
terraform validate
terraform plan

cd ../cosmos/ansible-openclaw
ansible-playbook --syntax-check playbooks/setup.yml
ansible openclaw -m ping
ansible-playbook playbooks/setup.yml --limit openclaw --check
ansible-playbook playbooks/setup.yml --limit openclaw-chinnu --check
```

After deployment, validate on the VM:

```bash
sudo systemctl status vault-agent.service certbot.timer --no-pager
sudo systemctl list-timers certbot.timer --no-pager
sudo stat /etc/letsencrypt/cloudflare.ini
sudo certbot renew --dry-run --cert-name openclaw.cosmos.cboxlab.com
```

Validate externally without `-k` or `--insecure`:

```bash
curl -I https://openclaw.cosmos.cboxlab.com/
```

## Rollback

- Stop and disable `vault-agent.service` if it cannot authenticate or render a
  valid credential file.
- Restore the last known-good Certbot credential file through the same secure
  operator workflow; never restore the currently invalid token.
- Remove the Certbot systemd dependency drop-in and reload systemd so the
  existing timer can operate independently.
- Keep the newly issued valid certificate and Nginx configuration in place.
- Revoke the OpenClaw AppRole SecretID and disable or remove only the
  `openclaw-certbot` role and policy after confirming no other consumer uses
  them. Do not alter the shared Cloudflare Vault document.

## Completion criteria

- [ ] `https://openclaw.cosmos.cboxlab.com` serves a currently valid certificate.
- [ ] Certbot's DNS challenge succeeds using the Vault-rendered credential.
- [ ] Both OpenClaw AppRoles have exact-path read access and cannot read
      unrelated Vault paths.
- [ ] No Cloudflare token or Vault SecretID exists in Git, Terraform state,
      Ansible output, shell history, or command arguments.
- [ ] Updating the canonical Vault property reaches the VM without rerunning
      Ansible.
- [ ] Vault Agent and Certbot recover automatically after VM reboot.
- [ ] Renewal and certificate-expiry failures produce actionable alerts.
- [ ] Kubernetes cert-manager and external-dns continue working throughout the
      rollout.
