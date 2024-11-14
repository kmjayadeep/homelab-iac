{ config, lib, pkgs, ... }: {

  programs.zsh.enable = true;

  # Set neovim as default editor
  programs.neovim.defaultEditor = true;
}

