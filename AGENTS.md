# AGENTS.md

## Scope
This file applies to the entire repository unless a deeper `AGENTS.md` exists.

## Project Overview
Homelab infrastructure-as-code repo with:
- Terraform stacks (`cloudflare/`, `hetzner/terraform/`, `cosmos/proxmox/`, `cosmos/pluto/`, `vault-config/`).
- Ansible projects (`cosmos/ansible-k3s/`, `cosmos/ansible-valheim/`, `hetzner/ansible-nova/`).
- NixOS flake images under `nixos-images/*`.

## Commands: Build / Lint / Test
No dedicated lint/test frameworks were found. Use the commands below to
validate or apply infra changes per component. There are no single-test
commands in the traditional sense; use the scoped commands to target one stack
or one host.

### Terraform (per directory)
Run these in the specific Terraform root directory.
- `terraform init`
- `terraform plan`
- `terraform apply`

Terraform directories include:
- `cloudflare/`
- `hetzner/terraform/`
- `cosmos/proxmox/`
- `cosmos/pluto/`
- `vault-config/`
- `terraform-modules/*` (modules only; no direct apply)

Single target: pass `-target` to plan/apply as needed:
- `terraform plan -target=resource.type.name`
- `terraform apply -target=resource.type.name`

### Terraform (Justfile helpers)
Some stacks provide `just` recipes.
- `cosmos/pluto/justfile`
  - `just plan`
  - `just apply`
- `cosmos/proxmox/justfile`
  - `just plan`
  - `just apply`

### Ansible (K3s master)
From `cosmos/ansible-k3s/`:
- Install collections: `ansible-galaxy collection install -r requirements.yml`
- Connectivity: `ansible all -m ping`
- Deploy master: `ansible-playbook playbooks/setup.yml`
- Start/stop/restart/update:
  - `ansible-playbook playbooks/start.yml`
  - `ansible-playbook playbooks/stop.yml`
  - `ansible-playbook playbooks/restart.yml`
  - `ansible-playbook playbooks/update.yml`

Worker nodes:
- Deploy: `ansible-playbook playbooks/setup-workers.yml`
- Start/stop:
  - `ansible-playbook playbooks/start-workers.yml`
  - `ansible-playbook playbooks/stop-workers.yml`

### Ansible (Valheim)
From `cosmos/ansible-valheim/`:
- Install collections: `ansible-galaxy collection install -r requirements.yml`
- Connectivity: `ansible all -m ping`
- Deploy: `ansible-playbook playbooks/setup.yml`
- Start/stop/restart/update:
  - `ansible-playbook playbooks/start.yml`
  - `ansible-playbook playbooks/stop.yml`
  - `ansible-playbook playbooks/restart.yml`
  - `ansible-playbook playbooks/update.yml`

### Ansible (Nova)
From `hetzner/ansible-nova/`:
- Deploy: `./deploy.sh`
- Update containers: `./update.sh`
- Manual playbook: `ansible-playbook playbooks/setup.yml`

### NixOS images
From `nixos-images/*` directories, use the Makefiles to rebuild.
Examples:
- `nixos-images/k3s/`: `make rebuild`
- `nixos-images/valheim/`: `make rebuild-fireland`
- `nixos-images/postgres/`: `make rebuild`
- `nixos-images/gatekeeper/`: `make rebuild`
- `nixos-images/github-runner/`: `make rebuild`
- `nixos-images/jd-workspace/`: `make rebuild`
- `nixos-images/golem/`: `make rebuild`
- `nixos-images/coder/`: `make rebuild`

Base image build (from `nixos-images/nixos-base-image/`):
- `nix build .#proxmox`

### Misc
There are no repo-wide build/test commands discovered.

## Code Style Guidelines
Follow existing patterns in each subdirectory. Keep changes small and
consistent with the surrounding files.

### General
- Prefer minimal, targeted edits.
- Do not introduce new tooling or lint rules without approval.
- Avoid secrets in the repo; use `.envrc` and environment variables instead.
- Keep comments concise and only when they add clarity.
- Respect `.gitignore` and never add `.tfvars` or credentials.

### Terraform
- Use snake_case for resource names, variables, locals, and outputs.
- Keep resource blocks ordered: `resource`, `data`, `module`, `variable`,
  `output` in separate files when possible.
- Prefer explicit `depends_on` only when required.
- Use `terraform fmt` formatting conventions (2-space indent, aligned `=`).
- Keep provider configuration in `providers.tf` or `terraform.tf` as done.
- Prefer variables over hard-coded values except for fixed infra constants.

### Ansible (YAML)
- Use 2-space indentation.
- Use snake_case for variables and group names.
- Keep tasks idempotent; prefer Ansible modules over shell commands.
- Use `name:` on tasks for readability.
- Store secrets in vault/group_vars or env vars, not inline.
- Group related tasks in roles and keep playbooks thin.

### Nix
- Follow existing flake layout per image.
- Use 2-space indentation and align with Nix community conventions.
- Prefer small, composable modules under `modules/`.
- Keep host-specific settings in `hosts/*.nix`.
- Avoid introducing non-flake Nix unless necessary.

### Shell Scripts
- Use `#!/usr/bin/env bash` and `set -e` (as in existing scripts).
- Quote variables and paths unless intentional word-splitting.
- Keep scripts simple and focused on a single workflow.

### Naming & Structure
- Match existing names for hosts (e.g., `titania`, `valkyrie`, `helios`).
- Use descriptive file names; avoid renaming unless required.
- Keep inventories and group vars under `inventory/` or `group_vars/`.

### Error Handling
- Terraform: surface errors by not suppressing CLI output.
- Ansible: rely on module return codes; avoid `ignore_errors` unless required.
- Shell: fail fast (`set -e`) and guard required env vars.

## Cursor / Copilot Rules
No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md`
were found in this repository.
