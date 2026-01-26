# AGENTS.md

## Scope
Applies to the entire repository unless a deeper `AGENTS.md` exists.

## Project Overview
Infrastructure-as-code repo with:
- Terraform stacks (`cloudflare/`, `hetzner/terraform/`, `cosmos/proxmox/`, `cosmos/pluto/`, `vault-config/`).
- Terraform modules (`terraform-modules/*`).
- Ansible projects (`cosmos/ansible-k3s/`, `cosmos/ansible-valheim/`, `hetzner/ansible-nova/`).
- NixOS flake images under `nixos-images/*`.
- Shell scripts and Justfiles for infra workflows.

## Commands: Build / Lint / Test
No dedicated lint/test frameworks were found. Use the scoped commands below to
validate or apply infra changes per component.

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

Single target plan/apply (single "test" equivalent):
- `terraform plan -target=resource.type.name`
- `terraform apply -target=resource.type.name`

Format/validate (if needed):
- `terraform fmt -recursive`
- `terraform validate`

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

Worker nodes (single host test):
- Deploy: `ansible-playbook playbooks/setup-workers.yml`
- Start/stop:
  - `ansible-playbook playbooks/start-workers.yml`
  - `ansible-playbook playbooks/stop-workers.yml`
- Single host limit: `ansible-playbook playbooks/setup-workers.yml -l host_or_group`

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
- Single host limit: `ansible-playbook playbooks/setup.yml -l host_or_group`

### Ansible (Nova)
From `hetzner/ansible-nova/`:
- Deploy: `./deploy.sh`
- Update containers: `./update.sh`
- Manual playbook: `ansible-playbook playbooks/setup.yml`
- Single host limit: `ansible-playbook playbooks/setup.yml -l host_or_group`

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

### Shell scripts
Run from the directory the script is in.
- Use `bash -n script.sh` for a quick syntax check.

### Misc
No repo-wide build/test commands discovered.

## Code Style Guidelines
Follow existing patterns in each subdirectory. Keep changes small and
consistent with the surrounding files.

### General
- Prefer minimal, targeted edits.
- Avoid introducing new tooling or lint rules without approval.
- Avoid secrets in the repo; use `.envrc` and environment variables instead.
- Keep comments concise and only when they add clarity.
- Respect `.gitignore` and never add `.tfvars` or credentials.
- Keep files organized under existing directories; avoid renames unless needed.

### Terraform
- Use snake_case for resource names, variables, locals, and outputs.
- Keep resource blocks ordered: `resource`, `data`, `module`, `variable`, `output`.
- Prefer explicit `depends_on` only when required.
- Use `terraform fmt` formatting conventions (2-space indent, aligned `=`).
- Keep provider configuration in `providers.tf` or `terraform.tf`.
- Prefer variables over hard-coded values except for fixed infra constants.
- Use clear module inputs/outputs; avoid unused variables.

### Ansible (YAML)
- Use 2-space indentation.
- Use snake_case for variables, role names, and group names.
- Keep tasks idempotent; prefer Ansible modules over shell commands.
- Use `name:` on tasks for readability.
- Store secrets in vault/group_vars or env vars, not inline.
- Group related tasks in roles and keep playbooks thin.
- Use `when:` guards instead of `ignore_errors` when possible.

### Nix
- Follow existing flake layout per image.
- Use 2-space indentation and align with Nix community conventions.
- Prefer small, composable modules under `modules/`.
- Keep host-specific settings in `hosts/*.nix`.
- Avoid introducing non-flake Nix unless necessary.
- Keep options explicit and avoid undeclared imports.

### Shell Scripts
- Use `#!/usr/bin/env bash` and `set -e` (as in existing scripts).
- Quote variables and paths unless intentional word-splitting.
- Keep scripts simple and focused on a single workflow.
- Prefer functions for repeated logic; keep error handling explicit.

### Naming & Structure
- Match existing names for hosts (e.g., `titania`, `valkyrie`, `helios`).
- Use descriptive file names; avoid renaming unless required.
- Keep inventories and group vars under `inventory/` or `group_vars/`.
- Prefer lower_snake_case for variables and files unless existing style differs.

### Types, Imports, Formatting
- Follow the existing file structure; do not reorder imports unless required.
- Preserve existing file formatting; avoid refactors that reflow unrelated lines.
- For Nix, keep `imports = [ ... ];` lists sorted when touching them.

### Error Handling
- Terraform: surface errors by not suppressing CLI output.
- Ansible: rely on module return codes; avoid `ignore_errors` unless required.
- Shell: fail fast (`set -e`) and guard required env vars.
- Nix: avoid partial failures; ensure required inputs are provided.

## Cursor / Copilot Rules
No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md`
were found in this repository.
