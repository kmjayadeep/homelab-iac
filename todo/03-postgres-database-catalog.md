# Phase 3: Database Catalog

Status: Not started

## Goal

Create a single source of truth for databases, users, backup policy, and platform metadata.

## Current state

Database names and users are hard-coded in `postgres.nix`.
Backup DB names are hard-coded separately in `backup.nix`.
Inventory documentation is maintained separately.

This causes drift, such as DBs existing but not being included in backups.

## Proposed catalog shape

A Nix-level catalog could look like:

```nix
{
  planka = {
    owner = "planka";
    backup = true;
    extensions = [];
    criticality = "P2";
  };

  immich = {
    owner = "immich";
    backup = true;
    extensions = [ "vector" ];
    criticality = "P1";
  };

  k3s = {
    owner = "k3s";
    backup = true;
    extensions = [];
    criticality = "P1";
  };
}
```

## What the catalog should drive

- `services.postgresql.ensureDatabases`
- `services.postgresql.ensureUsers`
- backup database list
- restore priority
- service documentation
- inventory metadata
- monitoring labels/annotations later, if useful

## Decisions to make

- Should the catalog live as a Nix module, a `.nix` data file, YAML, or Markdown table?
- Should app passwords be in the catalog? Proposed answer: no, keep secrets separate.
- Should excluded DBs be allowed? Proposed answer: yes, with `backup = false` and a reason.

## Deliverables

- [ ] Create database catalog file.
- [ ] Refactor `postgres.nix` to generate DBs/users from catalog.
- [ ] Refactor `backup.nix` to generate backup list from catalog where `backup = true`.
- [ ] Document how to onboard a DB by editing the catalog.
- [ ] Add explicit backup exclusion reason if any DB is not backed up.

## Validation

- Adding a DB to the catalog creates the DB/user and includes it in backups by default.
- There is no separate hand-maintained backup list.
- Existing DBs continue to work after refactor.
