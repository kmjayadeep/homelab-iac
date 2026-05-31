# Phase 3: Database Catalog

Status: Done

## Goal

Create a single source of truth for databases, users, backup policy, and platform metadata.

## Current state

Database names, owners, backup policy, criticality, and restore priority are defined in `nixos-images/postgres/modules/postgres-catalog.nix`.

`postgres.nix` consumes the catalog to generate `ensureDatabases` and `ensureUsers`.
`backup.nix` consumes the same catalog to select databases where `backup = true`.

## Implemented catalog shape

The Nix-level catalog looks like:

```nix
{
  databases = {
    immich = {
      owner = "immich";
      backup = true;
      criticality = "P1";
      extensions = [ "pgvector" ];
      restorePriority = "high";
    };
  };

  extraUsers = [
    {
      name = "pgweb";
      reason = "pgweb admin/visualization connection user";
    }
  ];
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

## Decisions made

- The catalog lives as a Nix data file: `nixos-images/postgres/modules/postgres-catalog.nix`.
- App passwords do not belong in the catalog; keep secrets separate.
- Excluded DBs are allowed with `backup = false`, but should include a comment explaining why.

## Deliverables

- [x] Create database catalog file.
- [x] Refactor `postgres.nix` to generate DBs/users from catalog.
- [x] Refactor `backup.nix` to generate backup list from catalog where `backup = true`.
- [x] Document how to onboard a DB by editing the catalog.
- [x] Add explicit backup exclusion reason if any DB is not backed up.

## Validation

- Adding a DB to the catalog creates the DB/user and includes it in backups by default.
- There is no separate hand-maintained backup list.
- Existing DBs continue to work after refactor.
