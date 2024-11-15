{
  config,
  lib,
  inputs,
  scripts,
  ...
}: {
  # Scripts to install
  home.packages = with scripts; [
    gitignore
    kcontext
    makescript
    mm
    notes
    pomo
    publiclocation
    pull
    push
    resticman
    tchat
    todo
    vic
    backup_nuc_restic
  ];
}

