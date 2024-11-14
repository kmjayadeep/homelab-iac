{
  config,
  lib,
  inputs,
  ...
}: {
  # Enable OMZ
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history.path = "${config.home.homeDirectory}/private/zsh/zsh_history";

    oh-my-zsh = {
      enable = true;
      plugins = [
        "z"
        "git"
        "sudo"
        "docker"
        "kubectl"
      ];
    };

    shellAliases = {
      sl = "eza";
      ls = "eza";
      l = "eza -l --icons";
      la = "eza -la --icons";
      ip = "ip --color=auto";
      v = "\${EDITOR:-nvim}";
      t = "task";
      review = "while true; do sleep  3;clear;task in; task today; task backlog; done;";
      sshk = "kitty +kitten ssh";
    };

    # Source additional shell aliases
    # It contains a loop for aliasing k8s commands, thats why it needs to be sourced
    initExtra = ''
      source $HOME/.bash_aliases
      export PATH=$PATH:~/.local/bin
    '';
  };

  home.file.".bash_aliases".source = ../assets/bash_aliases;

  # zsh prompt
  programs.starship = {
    enable = true;
  };

  # Set neovim as editor
  programs.neovim.defaultEditor = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}

