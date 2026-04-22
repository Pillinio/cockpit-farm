-- M1: Uniqueness auf data_imports.file_hash — aktive Imports only.
-- Rolled-back Imports schließen einen späteren Re-Import desselben Files nicht aus.
-- Verhindert TOCTOU-Races im commit-import Edge Function.

create unique index if not exists ux_data_imports_file_hash_active
  on data_imports(file_hash)
  where file_hash is not null and status <> 'rolled_back';
